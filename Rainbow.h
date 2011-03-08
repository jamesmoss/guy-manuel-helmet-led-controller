#ifndef Rainbow_h
#define Rainbow_h
//=============================================
//MBI5168
#define SH_DIR_OE    DDRC
#define SH_DIR_SDI   DDRC
#define SH_DIR_CLK   DDRC
#define SH_DIR_LE    DDRC

#define SH_BIT_OE    0x08
#define SH_BIT_SDI   0x01
#define SH_BIT_CLK   0x02
#define SH_BIT_LE    0x04

#define SH_PORT_OE   PORTC
#define SH_PORT_SDI  PORTC
#define SH_PORT_CLK  PORTC
#define SH_PORT_LE   PORTC
//============================================
#define clk_rising  {SH_PORT_CLK&=~SH_BIT_CLK;SH_PORT_CLK|=SH_BIT_CLK;}
#define le_high     {SH_PORT_LE|=SH_BIT_LE;}
#define le_low      {SH_PORT_LE&=~SH_BIT_LE;}
#define enable_oe   {SH_PORT_OE&=~SH_BIT_OE;}
#define disable_oe  {SH_PORT_OE|=SH_BIT_OE;}

#define shift_data_1     {SH_PORT_SDI|=SH_BIT_SDI;}
#define shift_data_0     {SH_PORT_SDI&=~SH_BIT_SDI;}
//============================================
#define open_line0	{PORTB=0x04;}
#define open_line1	{PORTB=0x02;}
#define open_line2	{PORTB=0x01;}
#define open_line3	{PORTD=0x80;}
#define open_line4	{PORTD=0x40;}
#define open_line5	{PORTD=0x20;}
#define open_line6	{PORTD=0x10;}
#define open_line7	{PORTD=0x08;}
#define close_all_line	{PORTD&=~0xf8;PORTB&=~0x07;}
//============================================

#define CheckRequest (g8Flag1&0x01)
#define SetRequest (g8Flag1|=0x01)
#define ClrRequest (g8Flag1&=~0x01)

//==============================================
#define waitingcmd 0x00
#define processing  0x01
#define checking  0x02

#define showPrefabnicatel 0x01
#define showChar 0x02
#define showColor 0x03

void _init(void)    // define the pin mode
{
  DDRD=0xff;
  DDRC=0xff;
  DDRB=0xff;
  PORTD=0;
  PORTB=0;
  close_all_line;
  
  int i;
  for(i = 3; i <=5; i++)
  {
    pinMode(i, OUTPUT); 
    analogWrite(i, 255); 
  }
  for(i = 9; i <=11; i++)
  {
    pinMode(i, OUTPUT); 
    analogWrite(i, 255); 
  }
}
void shift_1_bit(unsigned char LS) 
{
  if(LS)
  { 
    shift_data_1;
  }
  else  
  {
    shift_data_0;
  } 
  clk_rising;
}
void shift_24_bit(int Red,int Green,int Blue)  
{
  unsigned char i;
  le_high;
  for (i=0;i<8;i++)
  {
    if ((Green<<i)&0x80)   shift_1_bit(1);
    else                 shift_1_bit(0);

  }
  for (i=0;i<8;i++)
  {
    if ((Red<<i)&0x80) shift_1_bit(1);
    else          shift_1_bit(0);
  }
  for (i=0;i<8;i++)
  {
    if ((Blue<<i)&0x80)  shift_1_bit(1);
    else             shift_1_bit(0);
  } 
  le_low;
}

#endif
