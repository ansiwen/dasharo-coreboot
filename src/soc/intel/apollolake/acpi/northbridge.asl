/* SPDX-License-Identifier: GPL-2.0-or-later */


Name (_HID, EisaId("PNP0A08"))	/* PCI Express Bus */
Name (_CID, EisaId("PNP0A03"))	/* PCI Bus */

Device (MCHC)
{
	Name (_ADR, 0x00000000)		/* Device 0 Function 0 */

	OperationRegion (MCHP, PCI_Config, 0x00, 0x100)
	Field (MCHP, DWordAcc, NoLock, Preserve)
	{
		Offset (0x60),	/* PCIEXBAR (0:0:0:60) */
		PXEN,	1,	/* Enable */
		PXSZ,	2,	/* PCI Express Size */
		    ,	25,
		PXBR,	11,	/* PCI Express Base Address */

		Offset (0xbc),	/* TOLUD (0:0:0:bc) */
		    ,	20,
		TLUD,   12,	/* Top of Lower Usable DRAM */
	}
}

External (A4GS, IntObj)
External (A4GB, IntObj)

/* Current Resource Settings */
Method (_CRS, 0, Serialized)
{
	Name (MCRS, ResourceTemplate ()
	{
		/* Bus Numbers */
		WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
				0x0000, 0x0000, 0x00ff, 0x0000, 0x0100)

		/* IO Region 0: 0x0000 - 0x0cf7 */
		DWordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
				0x0000, 0x0000, 0x0cf7, 0x0000, 0x0cf8)

		/* PCI Config Space */
		Io (Decode16, 0x0cf8, 0x0cf8, 0x0001, 0x0008)

		/* IO Region 1: 0x1000 - 0xffff */
		DWordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
				0x0000, 0x01000, 0xffff, 0x0000, 0xf000)

		/*
		 * Descriptor:	Legacy VGA video RAM
		 * Start:	0xa0000
		 * End:		0xbffff
		 */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
				Cacheable, ReadWrite,
				0x00000000, 0x000a0000, 0x000bffff, 0x00000000,
				0x00020000,,,)

		/*  OPROM reserved (0xc0000-0xc3fff) */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
			Cacheable, ReadWrite,
			0x00000000, 0x000c0000, 0x000c3fff, 0x00000000,
			0x00004000)

		/* OPROM reserved (0xc4000-0xc7fff) */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
			Cacheable, ReadWrite,
			0x00000000, 0x000c4000, 0x000c7fff, 0x00000000,
			0x00004000)

		/* OPROM reserved (0xc8000-0xcbfff) */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
			Cacheable, ReadWrite,
			0x00000000, 0x000c8000, 0x000cbfff, 0x00000000,
			0x00004000)

		/* OPROM reserved (0xcc000-0xcffff) */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
			Cacheable, ReadWrite,
			0x00000000, 0x000cc000, 0x000cffff, 0x00000000,
			0x00004000)

		/* OPROM reserved (0xd0000-0xd3fff) */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
			Cacheable, ReadWrite,
			0x00000000, 0x000d0000, 0x000d3fff, 0x00000000,
			0x00004000)

		/* OPROM reserved (0xd4000-0xd7fff) */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
			Cacheable, ReadWrite,
			0x00000000, 0x000d4000, 0x000d7fff, 0x00000000,
			0x00004000)

		/* OPROM reserved (0xd8000-0xdbfff) */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
			Cacheable, ReadWrite,
			0x00000000, 0x000d8000, 0x000dbfff, 0x00000000,
			0x00004000)

		/* OPROM reserved (0xdc000-0xdffff) */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
			Cacheable, ReadWrite,
			0x00000000, 0x000dc000, 0x000dffff, 0x00000000,
			0x00004000)

		/* BIOS Extension (0xe0000-0xe3fff) */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
			Cacheable, ReadWrite,
			0x00000000, 0x000e0000, 0x000e3fff, 0x00000000,
			0x00004000)

		/* BIOS Extension (0xe4000-0xe7fff) */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
			Cacheable, ReadWrite,
			0x00000000, 0x000e4000, 0x000e7fff, 0x00000000,
			0x00004000)

		/* BIOS Extension (0xe8000-0xebfff) */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
			Cacheable, ReadWrite,
			0x00000000, 0x000e8000, 0x000ebfff, 0x00000000,
			0x00004000)

		/* BIOS Extension (0xec000-0xeffff) */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
			Cacheable, ReadWrite,
			0x00000000, 0x000ec000, 0x000effff, 0x00000000,
			0x00004000)

		/* System BIOS (0xf0000-0xfffff) */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
			Cacheable, ReadWrite,
			0x00000000, 0x000f0000, 0x000fffff, 0x00000000,
			0x00010000)

		/*
		 * PCI MMIO Region (TOLUD - PCI extended base MMCONF)
		 * This assumes that MMCONF is placed after PCI config space,
		 * and that no resources are allocated after the MMCONF region.
		 * This works, since MMCONF is hardcoded to 0xe00000000.
		 */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
				NonCacheable, ReadWrite,
				0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000,,, PM01)

		/*
		 * PCI Memory Region above 4 GiB
		 * (TOUUD - (TOUUD + ABOVE_4G_MMIO_SIZE))
		 */
		QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
				NonCacheable, ReadWrite,
				0x00000000, 0x00010000, 0x0001ffff, 0x00000000,
				0x00010000,,, PM02)

		/* TPM Area (0xfed40000-0xfed47fff) */
		DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
			Cacheable, ReadWrite,
			0x00000000, 0xfed40000, 0xfed47fff, 0x00000000,
			0x00008000)
	})

	/* Find PCI resource area in MCRS */
	CreateDwordField (MCRS, PM01._MIN, PMIN)
	CreateDwordField (MCRS, PM01._MAX, PMAX)
	CreateDwordField (MCRS, PM01._LEN, PLEN)

	/* Read C-Unit PCI CFG Reg. 0xBC for TOLUD (shadow from B-Unit) */
	PMIN = ^MCHC.TLUD << 20
	/* Use PCR base to ensure PMAX below GPIO controllers attached to _SB */
	PMAX = CONFIG_PCR_BASE_ADDRESS & 0xF0000000

	/* Calculate PCI MMIO Length */
	PLEN = PMAX - PMIN + 1

	/* Patch PM02 range based on Memory Size */
	If (A4GS == 0) {
		CreateQwordField (MCRS, PM02._LEN, MSEN)
		MSEN = 0
	} Else {
		CreateQwordField (MCRS, PM02._MIN, MMIN)
		CreateQwordField (MCRS, PM02._MAX, MMAX)
		CreateQwordField (MCRS, PM02._LEN, MLEN)
		/* Set 64bit MMIO resource base and length */
		MLEN = A4GS
		MMIN = A4GB
		MMAX = MMIN + MLEN - 1
	}

	Return (MCRS)
}

Device (PDRC)	/* PCI Device Resource Consumption */
{
	Name (_HID, EisaId("PNP0C02"))
	Name (_UID, 1)

	Method (_CRS, 0, Serialized)
	{
		Name (BUF0, ResourceTemplate ()
		{
			/* Local APIC range (0xfee0_0000 to 0xfeef_ffff) */
			Memory32Fixed (ReadOnly, 0x0fee00000, 0x00010000, LIOH)
		})

		Return (BUF0)
	}
}

/* GFX 00:02.0 */
#include <drivers/intel/gma/acpi/gfx.asl>
