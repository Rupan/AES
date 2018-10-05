phys = 0x00010000;
SECTIONS
{
  .text phys : AT(phys) {
    code = .;
    *(.text)
    . = ALIGN(4096);
  }
  .rodata : AT(phys + (rodata - code))
  {
    rodata = .;
    *(.rodata)
    . = ALIGN(4096);
  }
  end = .;
}
