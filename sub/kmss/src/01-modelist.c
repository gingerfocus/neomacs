/* Listing available connector modes
 *
 * This demo iterates over the list of connectors provided by KMS, and prints
 * all available modes.
 */

#include <fcntl.h>
#include <stdio.h>
#include <xf86drmMode.h>

int main(int argc, char *argv[]) {
	int drm_fd = open("/dev/dri/card0", O_RDWR | O_NONBLOCK);
	if (drm_fd < 0) {
		perror("open failed");
		return 1;
	}

	drmModeRes *resources = drmModeGetResources(drm_fd);
	for (int i = 0; i < resources->count_connectors; i++) {
		uint32_t conn_id = resources->connectors[i];
		drmModeConnector *conn = drmModeGetConnector(drm_fd, conn_id);

		if (conn->connection != DRM_MODE_CONNECTED) {
			drmModeFreeConnector(conn);
			continue;
		}

		printf("Modes for connector %u:\n", conn->connector_id);
		for (int i = 0; i < conn->count_modes; i++) {
			drmModeModeInfo *mode = &conn->modes[i];
			printf("%dx%d %dHz\n", mode->hdisplay, mode->vdisplay, mode->vrefresh);
		}

		drmModeFreeConnector(conn);
	}
	drmModeFreeResources(resources);

	return 0;
}
