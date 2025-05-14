/* Select KMS resources
 *
 * This demo reads the current KMS configuration and retrieves:
 *
 * - The first CRTC currently lighted on
 * - The mode used by the CRTC
 * - The primary plane connected to the CRTC
 */

#include <assert.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <xf86drm.h>
#include <xf86drmMode.h>

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

	return 0;
}
