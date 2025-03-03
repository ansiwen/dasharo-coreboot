/* SPDX-License-Identifier: GPL-2.0-only */

#include <dasharo/options.h>
#include <ec/system76/ec/commands.h>
#include <ec/acpi/ec.h>
#include <ec/system76/ec/acpi.h>
#include <fmap.h>
#include <lib.h>
#include <security/vboot/vboot_common.h>
#include <smbios.h>
#include <soc/ramstage.h>

struct smfi_cmd_set_fan_curve {
	uint8_t fan;
	struct fan_curve curve;
} __packed;

struct fan_curve fan_curve_silent = {
	{ .temp = 0,   .duty = 20  },
	{ .temp = 65,  .duty = 25  },
	{ .temp = 75,  .duty = 35  },
	{ .temp = 85,  .duty = 100 }
};

struct fan_curve fan_curve_performance = {
	{ .temp = 0,   .duty = 25 },
	{ .temp = 55,  .duty = 35 },
	{ .temp = 75,  .duty = 60 },
	{ .temp = 85,  .duty = 100}
};

const char *smbios_system_sku(void)
{
	return "Not Applicable";
}

smbios_enclosure_type smbios_mainboard_enclosure_type(void)
{
	return SMBIOS_ENCLOSURE_NOTEBOOK;
}

smbios_wakeup_type smbios_system_wakeup_type(void)
{
	return SMBIOS_WAKEUP_TYPE_POWER_SWITCH;
}

static void set_fan_curve(void)
{
	int i;
	uint8_t selection = get_fan_curve_option();
	struct smfi_cmd_set_fan_curve cmd;

	switch (selection) {
	case FAN_CURVE_OPTION_PERFORMANCE:
		cmd.curve = fan_curve_performance;
		break;
	case FAN_CURVE_OPTION_SILENT:
	default:
		cmd.curve = fan_curve_silent;
		break;
	}

	for (i = 0; i < (CONFIG(EC_SYSTEM76_EC_DGPU) ? 2 : 1); ++i) {
		cmd.fan = i;
		system76_ec_smfi_cmd(CMD_FAN_CURVE_SET, sizeof(cmd), (uint8_t *)&cmd);
	}
}

static void set_camera_enablement(void)
{
	bool enabled = get_camera_option();

	system76_ec_smfi_cmd(CMD_CAMERA_ENABLEMENT_SET, sizeof(enabled), (uint8_t *)&enabled);
}

static void set_battery_thresholds(void)
{
	struct battery_config bat_cfg;

	get_battery_config(&bat_cfg);

	system76_ec_set_bat_threshold(BAT_THRESHOLD_START, bat_cfg.start_threshold);
	system76_ec_set_bat_threshold(BAT_THRESHOLD_STOP, bat_cfg.stop_threshold);
}

static void set_power_on_ac(void)
{
	struct smfi_option_get_cmd {
		uint8_t index;
		uint8_t value;
	} __packed cmd = {
		OPT_POWER_ON_AC,
		0
	};

	cmd.value = dasharo_get_power_on_after_fail();

	system76_ec_smfi_cmd(CMD_OPTION_SET, sizeof(cmd), (uint8_t *)&cmd);
}

static void mainboard_init(void *chip_info)
{
	config_t *cfg = config_of_soc();
	struct device *wlan_dev = pcidev_on_root(0x1c, 7);
	struct device *cnvi_dev = pcidev_on_root(0x14, 3);
	bool radio_enable = get_wireless_option();

	printk(BIOS_DEBUG, "Wireless is %sabled\n", radio_enable ? "en" : "dis");

	wlan_dev->enabled = radio_enable;
	cnvi_dev->enabled = radio_enable;
	cfg->cnvi_bt_core = radio_enable;
	cfg->cnvi_bt_audio_offload = radio_enable;
	cfg->usb2_ports[9].enable = radio_enable;

	system76_ec_smfi_cmd(CMD_WIFI_BT_ENABLEMENT_SET, 1, (uint8_t *)&radio_enable);

	set_fan_curve();
	set_camera_enablement();
	set_battery_thresholds();
	set_power_on_ac();
}

#if CONFIG(GENERATE_SMBIOS_TABLES)
static uint8_t read_proprietary_ec_version(uint8_t *data)
{
	int i, result;
	char ec_version[16];

	if (!data)
		return -1;

	if (send_ec_command(0x93))
		return -1;

	for (i = 0; i < 16 - 1; i++) {

		result = recv_ec_data();
		if (result != -1)
			ec_version[i] = result & 0xff;

		if (ec_version[i] == '$') {
			ec_version[i] = '\0';
			break;
		}
	}
	ec_version[15] = '\0';

	data[0] = '1';
	data[1] = '.';

	strcpy((char *)&data[2], ec_version);

	return 0;
}

static void mainboard_smbios_strings(struct device *dev, struct smbios_type11 *t)
{
	char ec_version[256];
	uint8_t result;

	result = system76_ec_read_version((uint8_t *)ec_version);

	/* If the command fails it mean we are running proprietary EC most likely */
	if (result != 0) {
		printk(BIOS_ERR, "Failed to read open EC firmware version\n");
		result = read_proprietary_ec_version((uint8_t *)ec_version);
		if (result == 0)
			t->count = smbios_add_string(t->eos, "EC: proprietary");
		else
			t->count = smbios_add_string(t->eos, "EC: unknown");
	} else {
		t->count = smbios_add_string(t->eos, "EC: open-source");
	}

	if (result == 0) {
		printk(BIOS_DEBUG, "EC firmware version: %s\n", ec_version);
		t->count = smbios_add_string(t->eos, strconcat("EC firmware version: ",
					     ec_version));
	} else {
		printk(BIOS_ERR, "Unable to probe EC firmware version\n");
		t->count = smbios_add_string(t->eos, "EC firmware version: unknown");
	}

}
#endif


static void mainboard_enable(struct device *dev)
{
#if CONFIG(GENERATE_SMBIOS_TABLES)
	dev->ops->get_smbios_strings = mainboard_smbios_strings;
#endif
}

struct chip_operations mainboard_ops = {
	.enable_dev = mainboard_enable,
	.init = mainboard_init,
};

void mainboard_silicon_init_params(FSP_S_CONFIG *params)
{
	// Enable reporting CPU C10 state over eSPI
	params->PchEspiHostC10ReportEnable = 1;

	// Pinmux configuration
	params->CnviRfResetPinMux = 0x194CE404; // GPP_F04
	params->CnviClkreqPinMux = 0x394CE605;  // GPP_F05

	params->LidStatus = system76_ec_get_lid_state();
}
