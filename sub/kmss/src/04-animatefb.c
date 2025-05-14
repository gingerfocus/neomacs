/* Show a framebuffer
 *
 * This demo selects a CRTC and a plane, and displays a static framebuffer
 * filled with red for 5 seconds.
 */

#include <assert.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>
#include <xf86drm.h>
#include <xf86drmMode.h>
#include <libdrm/drm_fourcc.h>

drmModeCrtc *crtc = NULL;
drmModeModeInfo mode = {0};
drmModePlane *plane = NULL;

uint64_t get_property_value(int drm_fd, uint32_t object_id,
		uint32_t object_type, const char *prop_name) {
	drmModeObjectProperties *props =
		drmModeObjectGetProperties(drm_fd, object_id, object_type);
	for (uint32_t i = 0; i < props->count_props; i++) {
		drmModePropertyRes *prop = drmModeGetProperty(drm_fd, props->props[i]);
		uint64_t val = props->prop_values[i];
		if (strcmp(prop->name, prop_name) == 0) {
			drmModeFreeProperty(prop);
			drmModeFreeObjectProperties(props);
			return val;
		}
		drmModeFreeProperty(prop);
	}
	abort(); // Oops, property not found
}

void add_property(int drm_fd, drmModeAtomicReq *req, uint32_t object_id,
		uint32_t object_type, const char *prop_name, uint64_t value) {
	uint32_t prop_id = 0;
	drmModeObjectProperties *props =
		drmModeObjectGetProperties(drm_fd, object_id, object_type);
	for (uint32_t i = 0; i < props->count_props; i++) {
		drmModePropertyRes *prop = drmModeGetProperty(drm_fd, props->props[i]);
		if (strcmp(prop->name, prop_name) == 0) {
			prop_id = prop->prop_id;
			break;
		}
	}
	assert(prop_id != 0);

	drmModeAtomicAddProperty(req, object_id, prop_id, value);
}

int main(int argc, char *argv[]) {
	int drm_fd = open("/dev/dri/card0", O_RDWR | O_NONBLOCK);
	if (drm_fd < 0) {
		perror("open failed");
		return 1;
	}

	if (drmSetClientCap(drm_fd, DRM_CLIENT_CAP_UNIVERSAL_PLANES, 1) != 0) {
		perror("drmSetClientCap(UNIVERSAL_PLANES) failed");
		return 1;
	}
	if (drmSetClientCap(drm_fd, DRM_CLIENT_CAP_ATOMIC, 1) != 0) {
		perror("drmSetClientCap(ATOMIC) failed");
		return 1;
	}

	drmModeRes *resources = drmModeGetResources(drm_fd);

	// Get the first CRTC currently lighted up
	for (int i = 0; i < resources->count_crtcs; i++) {
		uint32_t crtc_id = resources->crtcs[i];
		crtc = drmModeGetCrtc(drm_fd, crtc_id);
		if (crtc->mode_valid) {
			break;
		}
		drmModeFreeCrtc(crtc);
		crtc = NULL;
	}
	assert(crtc != NULL);
	printf("Using CRTC %u\n", crtc->crtc_id);

	mode = crtc->mode;
	printf("Using mode %dx%d %dHz\n", mode.hdisplay, mode.vdisplay, mode.vrefresh);

	// Get the primary plane connected to the CRTC
	drmModePlaneRes *planes = drmModeGetPlaneResources(drm_fd);
	for (uint32_t i = 0; i < planes->count_planes; i++) {
		uint32_t plane_id = planes->planes[i];
		plane = drmModeGetPlane(drm_fd, plane_id);
		uint64_t plane_type = get_property_value(drm_fd, plane_id,
			DRM_MODE_OBJECT_PLANE, "type");
		if (plane->crtc_id == crtc->crtc_id &&
				plane_type == DRM_PLANE_TYPE_PRIMARY) {
			break;
		}
		drmModeFreePlane(plane);
		plane = NULL;
	}
	assert(plane != NULL);
	printf("Using plane %u\n", plane->plane_id);

	drmModeFreePlaneResources(planes);
	drmModeFreeResources(resources);

	// Allocate a buffer and get a driver-specific handle back
	int width = mode.hdisplay;
	int height = mode.vdisplay;
	struct drm_mode_create_dumb create = {
		.width = width,
		.height = height,
		.bpp = 32,
	};
	drmIoctl(drm_fd, DRM_IOCTL_MODE_CREATE_DUMB, &create);
	uint32_t handle = create.handle;
	uint32_t stride = create.pitch;
	uint32_t size = create.size;

	// Create the DRM framebuffer object
	uint32_t handles[4] = { handle };
	uint32_t strides[4] = { stride };
	uint32_t offsets[4] = { 0 };
	uint32_t fb_id = 0;
	drmModeAddFB2(drm_fd, width, height, DRM_FORMAT_XRGB8888,
		handles, strides, offsets, &fb_id, 0);
	printf("Allocated FB %u\n", fb_id);

	// Create a memory mapping
	struct drm_mode_map_dumb map = { .handle = handle };
	drmIoctl(drm_fd, DRM_IOCTL_MODE_MAP_DUMB, &map);
	uint8_t *data = mmap(0, size, PROT_READ | PROT_WRITE, MAP_SHARED, drm_fd, map.offset);

	uint8_t color[] = { 0x00, 0x00, 0xFF, 0xFF }; // B, G, R, X
	int inc = 1, dec = 2;
	for (int i = 0; i < 60 * 5; i++) {
		color[inc] += 15;
		color[dec] -= 15;
		if (color[dec] == 0) {
			dec = inc;
			inc = (inc + 2) % 3;
		}

		for (int y = 0; y < height; y++) {
			for (int x = 0; x < width; x++) {
				size_t offset = y * stride + x * sizeof(color);
				memcpy(&data[offset], color, sizeof(color));
			}
		}

		// Submit an atomic commit
		drmModeAtomicReq *req = drmModeAtomicAlloc();

		uint32_t plane_id = plane->plane_id;
		add_property(drm_fd, req, plane_id, DRM_MODE_OBJECT_PLANE, "FB_ID", fb_id);
		add_property(drm_fd, req, plane_id, DRM_MODE_OBJECT_PLANE, "SRC_X", 0);
		add_property(drm_fd, req, plane_id, DRM_MODE_OBJECT_PLANE, "SRC_Y", 0);
		add_property(drm_fd, req, plane_id, DRM_MODE_OBJECT_PLANE, "SRC_W", width << 16);
		add_property(drm_fd, req, plane_id, DRM_MODE_OBJECT_PLANE, "SRC_H", height << 16);
		add_property(drm_fd, req, plane_id, DRM_MODE_OBJECT_PLANE, "CRTC_X", 0);
		add_property(drm_fd, req, plane_id, DRM_MODE_OBJECT_PLANE, "CRTC_Y", 0);
		add_property(drm_fd, req, plane_id, DRM_MODE_OBJECT_PLANE, "CRTC_W", width);
		add_property(drm_fd, req, plane_id, DRM_MODE_OBJECT_PLANE, "CRTC_H", height);

		uint32_t flags = DRM_MODE_ATOMIC_NONBLOCK;
		int ret = drmModeAtomicCommit(drm_fd, req, flags, NULL);
		if (ret != 0) {
			perror("drmModeAtomicCommit failed");
			return 1;
		}

		// 60Hz, more or less
		struct timespec ts = { .tv_nsec = 16666667 };
		nanosleep(&ts, NULL);
	}

	return 0;
}
