//**************************************************************//
//  Name    : Guy Manuel Daft Punk Helmet LED controller        //
//  Author  : James Moss (jamesmoss.co.uk)                      //
//  Date    : 16 January 2011                                 	//
//  Version : 1.0.1 						//
//  License : MIT	                                        //
//  Notes   : Developed for Volpin (volpinprops.blogspot.com)   //
//          : Controls the flashing / animated leds in          //
//          : a Daft Punk replica helmet                        //
//****************************************************************/

#include "Potentiometer.h"
#include "Math.h"
//#include "Rainbow.h" // Rainbowduino libraries, dont include these if using arduino

/* -- PIN DEFINITIONS ----------------------------------------- */

// Outputs
int latchPin = 8;
int clockPin = 12;
int dataPin  = 11;

// Inputs
int modePotPin = 1;
int speedPotPin = 2;
int lineInPin = 3;

/* -- PROGRAM CONFIG ----------------------------------------- */

// Tweak these values to suit your preference
unsigned int earSpeed = 300; // Time in milliseconds between ear LED animation frames
unsigned int earPause = 4; // Amount of frames to wait before running the ear animation again (max 250)
unsigned int cheekSpeed = 300; // Time in milliseconds between cheek LED (white LEDs) animation frames
unsigned int chinSpeed = 500; // Time in milliseconds between chin LED (red/green/yellow LEDs) animation frames

/* -- PROGRAM VARIABLES ----------------------------------------- */

// dont edit these unless you really know what you're doing
unsigned int barSpeed = 100; // Time in milliseconds between bar LED animation frames
unsigned char earFrame = 1;
int barFrame = 0;
unsigned char barAnimation = 1;
char cheekFrame = 0;
byte earBuffer = 0; 
byte cheekBuffer = 0;
byte barBuffer = 0;
byte chinBuffer = 0;
unsigned long lastEarFrame = 0;
unsigned long lastCheekFrame = 0;
unsigned long lastBarFrame = 0;
unsigned long lastChinFrame = 0;

// pots
Potentiometer modePot = Potentiometer(modePotPin);
Potentiometer speedPot = Potentiometer(speedPotPin);

unsigned char NumTab[9]=
{
  B00000000,
  B00000001,
  B00000010,
  B00000100,
  B00001000,
  B00010000,
  B00100000,
  B01000000,
  B10000000
};

// Called when the arduino loads
void setup()
{
  // Rainbowduino code, comment out if using arduino
  //_init();
  
  randomSeed(analogRead(0)); // Initalise the random number generator with noise on pin 1
 
  // set the pin modes
  pinMode(latchPin, OUTPUT);
  pinMode(clockPin, OUTPUT);
  pinMode(dataPin, OUTPUT);
  
   // init the pots
  modePot.setSectors(10);
  speedPot.setSectors(100);
}

void loop()
{
  checkInputs();
  
  unsigned long currentTime = millis();
  
  // check to see if its time to animate the ear  
  if(currentTime > (lastEarFrame+earSpeed))
  {
    animateEar();
    lastEarFrame = currentTime;
  }
  
  // check to see if its time to animate the cheek  
  if(currentTime > (lastCheekFrame+cheekSpeed))
  {
    animateCheek();
    lastCheekFrame = currentTime;
  }
  
  // check to see if its time to animate the coloured bars  
  if(currentTime > (lastBarFrame+barSpeed))
  {
    animateBars();
    lastBarFrame = currentTime;
  }
  
  // check to see if its time to animate the chin leds  
  if(currentTime > (lastChinFrame+chinSpeed))
  {
    animateChin();
    lastChinFrame = currentTime;
  }
  
  // temporary buffer which ear, jack and chin LEDs get merged into 
  byte tempBuffer = B00000000;
  tempBuffer |= earBuffer;
  tempBuffer |= B00001000; // jack LEDs, these are always on
  tempBuffer |= chinBuffer << 4; // shift the chinBuffer left 4 bits
  
  
  // If the animations are being sent to the incorrect shift register try 
  // moving the calls to the shiftOut() function around.
  // If the animations are coming out back to front change LSBFIRST to MSBFIRST
  // this tells the shiftOut function which order to send the bits, right to 
  // left (LSB) or left to right (MSB)
  digitalWrite(latchPin, LOW);
  shiftOut(dataPin, clockPin, LSBFIRST, barBuffer);   
  shiftOut(dataPin, clockPin, LSBFIRST, cheekBuffer);
  shiftOut(dataPin, clockPin, LSBFIRST, tempBuffer);
  digitalWrite(latchPin, HIGH);
  
  
  // Rainbowduino code, comment out if using with arduino
 // shift_24_bit(/*earBuffer*/0, tempBuffer, cheekBuffer); //RGB
  
  delay(5);
}

void checkInputs()
{
  // this creates a logarithmic curve so that its easier to 
  // adjust the faster speeds
  short int pot = speedPot.getSector();
  barSpeed = ceil(pow(pot, 3)*0.001);
  
  
  // check mode
  static char lastMode = 0;
  unsigned char p = modePot.getSector();
  if(lastMode != p)
  {
    // change mode
    barFrame = 0;
    barAnimation = p;
    lastMode = p;
  }
}

/* -- EAR ANIMATIONS ----------------------------------------- */

void animateEar()
{
     
  switch(earFrame)
  {
    case 1:
      earBuffer = B00000100;
      break;
    case 2:
      earBuffer = B00000110;
      break;
    case 3:
      earBuffer = B00000010;
      break;  
    case 4:
      earBuffer = B00000011;
      break;
    case 5:
      earBuffer = B00000001;
      break;
    default:
      earBuffer = B00000000;
      if(earFrame-5 > earPause) // 5 is the number of frames in the animation
      {
        earFrame = 0;
      } 
      break;    
  }

  
 earFrame++;
}

/* -- CHEEK ANIMATIONS -------------------------------------- */

void animateCheek()
{
  cheekBuffer = B00000000;
  cheekBuffer |= NumTab[abs(cheekFrame-7)+1];
  cheekFrame++;
  
  if(cheekFrame > 13)
  {
    cheekFrame = 0;
  }
}

/* -- BAR ANIMATIONS ----------------------------------------- */

void animateBars()
{
  barBuffer = B00000000;
  
  switch(barAnimation)
  {
    case 1: singleChaser();       break;
    case 2: multiChaser();        break;
    case 3: bounce();             break;
    case 4: growOutwards();       break;
    case 5: growInwards();        break;
    case 6: simpleStrobe();       break; 
    case 7: singleRandomStrobe(); break; 
    case 8: multiRandomStrobe();  break; 
    case 9: allBarsOn();          break;
    case 10: twoRandomInverted();      break;
    
    // just in case the pot breaks :)
    default: singleChaser();      break;  
  }

}

/* -- CHIN ANIMATIONS ----------------------------------------- */

void animateChin()
{
  static char chinFrame = 0;
  
  chinBuffer = B00000000;
  
  char i;
  for(i = 1; i <= 4; i++)
  {
    if(random(0, 4) == 0)
    {
      chinBuffer |= NumTab[i];
    }
  }
  
  if(chinFrame > 4)
  {
    chinFrame = 0;
  }
}

/* --------------------------------------------------------------- 
    turnOnBar(int pinNum)
    Takes a integer between 1 and 8 and turns the corresponding 
    bar on.
---------------------------------------------------------------- */

void turnOnBar(int pinNum)
{
  if(pinNum >= 1 && pinNum <= 8)
  {
    barBuffer |= NumTab[pinNum];
  }
}

/* --------------------------------------------------------------- 
    The following functions are the different animations
    for the bars, 
---------------------------------------------------------------- */
  
  

/* -- 1: SINGLE CHASER ----------------------------------------- */

void singleChaser()
{
  barFrame++;
  
   if(barFrame > 8)
   {
     barFrame = 1;
   }
   
  turnOnBar(barFrame);
}

/* -- 2: MULTI CHASER ----------------------------------------- */

void multiChaser()
{
  barFrame++;

   if(barFrame > 11)
   {
     barFrame = 1;
   }
   
   
  turnOnBar(barFrame);
  turnOnBar(barFrame - 1);
  turnOnBar(barFrame - 2);

}

/* -- 3: BOUNCE ----------------------------------------- */

void bounce()
{
  char position = abs(barFrame-7)+1;
  barFrame++;
  if(barFrame > 13)
  {
    barFrame = 0;
  }
   
  turnOnBar(position);

}

/* -- 4: GROW OUTWARDS ----------------------------------------- */

void growOutwards()
{
  barFrame++;
  
  if(barFrame > 5)
  {
    barFrame = 1;
  }  
  char pos = barFrame - 2;
  char i;
    
  for(i = (4-pos); i <= 4; i++)
  {
    turnOnBar(i);
    turnOnBar(9-i);
  }    
}

/* -- 5: GROW INWARDS ----------------------------------------- */

void growInwards()
{
  barFrame++;
  
  if(barFrame > 5)
  {
    barFrame = 1;
  } 
  
  char pos = barFrame - 1;
  char i;
    
  for(i = 1; i <= pos; i++)
  {
      turnOnBar(i);
      turnOnBar(9-i);
  }    
}

/* -- 6: SIMPLE STROBE --------------------------------------- */

void simpleStrobe()
{
  if(barFrame == 0)
  {   
    barBuffer = B11111111;
    barFrame = 1;
  }
  else
  {
    barFrame = 0;
  }

}

/* -- 7: SINGLE RANDOM STROBE ----------------------------------------- */

void singleRandomStrobe()
{
  turnOnBar(random(1, 9));
}

/* -- 8: MULTI RANDOM STROBE ----------------------------------------- */

void multiRandomStrobe()
{
  int randNum = random(0, 4);
  int i = 0;
  
  for(i = 0; i <= randNum; i++)
  {
    turnOnBar(random(1, 9));
  }
}

/* -- 9: ALL BARS ON ----------------------------------------- */

void allBarsOn()
{
  int i;
  
  // loop through the bars and turn them all on
  for(i = 1; i <= 8; i++)
  {
    turnOnBar(i);
  }
}

/* -- 10: TWO RANDOMLY INVERTED ----------------------------------------- */

void twoRandomInverted()
{
  int i, randNum2;
  int randNum1 = random(1, 9);
  
  do {
      // generate a different random number
      int randNum2 = random(1, 9);
      
  } while(randNum1 == randNum2);
  
  
  // loop through the bars and turn them all on
  for(i = 1; i <= 8; i++)
  {
    if(i != randNum1 && i != randNum2)
    {
      turnOnBar(i);
    }
  }
}
