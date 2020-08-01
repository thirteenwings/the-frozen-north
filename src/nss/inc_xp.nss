//::///////////////////////////////////////////////
//::
//::////////////////////////////////////////////////////
//:: Some snippets By: Kato. Name: k_inc_xp_system
//:: Created On: December 2010
//::////////////////////////////////////////////////////

#include "inc_debug"

// The amount of bonus or penalty XP modified by level.
const float QUEST_XP_LEVEL_ADJUSTMENT_MODIFIER = 0.1;

const float BASE_XP = 4.0;

// The XP tiers for quests.
const float QUEST_XP_T1 = 50.0;
const float QUEST_XP_T2 = 100.0;
const float QUEST_XP_T3 = 200.0;
const float QUEST_XP_T4 = 400.0;

// The maximum XP limit for a single kill
const float XP_MAX = 20.0;

// The maximum XP limit for a boss
const float XP_MAX_BOSS = 50.0;

// The % CR XP awarded to party when a trap or summon is the killer.
const float XP_NOPC = 1.00;

// XP percentage bonus/penalty based on wisdom score
// 12 wisdom - 2 wis score = 4% xp bonus
const float WISDOM_BONUS = 0.02;

// Races with at least one level in their favored class OR humans/half-elves who are triple class
// get a bonus to XP. 1.2 is equal to a 20% bonus.
const float FAVORED_BONUS = 1.2;

// Human/Half elves who are dual classed have this bonus.
// 1.1 is equal to a 10% bonus.
const float DUAL_CLASS_BONUS = 1.1;

// Set this value to 1 in order to display debug infos.
// Very useful during setup
const int K_DEBUG_TEXT = 0;

// The maximum party level gap. If the gap is greater/equal, no CR xp.
// Only the members within distance are included in gap
const int PARTY_GAP_MAX = 4;

// 4 / (2 + party size*1) = 60% xp with pc size of 2 and 0 henchman
const float PARTY_SIZE_BASE_MOD = 2.0;
const float PARTY_SIZE = 1.0;


// **** SYSTEM SETTINGS END - YOU SHOULD NOT MODIFY ANYTHING BELOW THIS! *******************************************




// ************ DECLARATIONS ****************************

// * The main function of the include, it distributes
// * xp to party members in a loop.
void GiveXP(object oKiller);


// Gives nXpAmount to oPC, wisdom adjusted
void GiveXPToPC(object oPC, float fXpAmount);

// Gives nXp amount to oPC, wisdom adjusted
// with bonuses/penalties related to the target level
void GiveQuestXPToPC(object oPC, int nTier, int nLevel);

// This function returns the level based on XP
int GetLevelFromXP(int nXP);

// ------------------ INTERNAL FUNCTIONS ----------------

// Courtesy of Sherincall (clippy) from discord
int Round(float f) { return FloatToInt(f +  (f > 0.0 ? 0.5 : -0.5) ); }

int GetLevelFromXP(int nXP)
{
   return FloatToInt(0.5 + sqrt(0.25 + (IntToFloat(nXP) / 500 )));
}


void GiveXPToPC(object oPC, float fXpAmount)
{
// Dead PCs do not get any XP
   if (GetIsDead(oPC)) return;

// Calculate wisdom bonus
   int nWisdomMod = GetAbilityScore(oPC, ABILITY_WISDOM) - 10;
   float fXpPercent = 1.0 + (IntToFloat(nWisdomMod) * WISDOM_BONUS);

   SendDebugMessage("Wisdom Percentage Modifier"+FloatToString(fXpPercent));

// Calculate favored bonus
   float fFavoredModifier = 1.0;
   int nRace = GetRacialType(oPC);
   switch (nRace)
   {
        case RACIAL_TYPE_DWARF:
            if (GetLevelByClass(CLASS_TYPE_FIGHTER, oPC) > 0) fFavoredModifier = FAVORED_BONUS;
            break;
        case RACIAL_TYPE_ELF:
        case RACIAL_TYPE_GNOME:
            if (GetLevelByClass(CLASS_TYPE_WIZARD, oPC) > 0) fFavoredModifier = FAVORED_BONUS;
            break;
        case RACIAL_TYPE_HALFLING:
            if (GetLevelByClass(CLASS_TYPE_ROGUE, oPC) > 0) fFavoredModifier = FAVORED_BONUS;
            break;
        case RACIAL_TYPE_HALFORC:
            if (GetLevelByClass(CLASS_TYPE_BARBARIAN, oPC) > 0) fFavoredModifier = FAVORED_BONUS;
            break;
        case RACIAL_TYPE_HUMAN:
        case RACIAL_TYPE_HALFELF:
            if (GetLevelByPosition(3, oPC) > 0)
            {
                fFavoredModifier = FAVORED_BONUS;
            }
            else if (GetLevelByPosition(2, oPC) > 0)
            {
                fFavoredModifier = DUAL_CLASS_BONUS;
            }
            break;
   }


   SendDebugMessage("Favored class percentage modifier: "+FloatToString(fFavoredModifier));


   float fAdjustedXpAmount = fXpPercent * fXpAmount * fFavoredModifier;

   SendDebugMessage("Adjusted XP: "+FloatToString(fAdjustedXpAmount));

   int nXP = Round(fAdjustedXpAmount);

// If the XP returned is less than or equal to 0, make it at least 1
   if (nXP <= 0) nXP = 1;

   int oPCXP = GetXP(oPC);

   SetXP(oPC, oPCXP + nXP);
}

void GiveQuestXPToPC(object oPC, int nTier, int nLevel)
{
   if (nTier == 0 || nLevel == 0) return;

   float fXP = 0.0;
   float fMod = 1.0;
   int nPCLevel = GetLevelFromXP(GetXP(oPC));
   int nAdjust = nLevel - nPCLevel;
   float fAdjust = IntToFloat(nAdjust) * QUEST_XP_LEVEL_ADJUSTMENT_MODIFIER;

   fMod = fMod + fAdjust;

// capped at 25% xp
   if (fMod < 0.25) fMod = 0.25;
// capped at 150% xp
   if (fMod > 1.5) fMod = 1.5;


   SendDebugMessage("Target quest XP level: "+IntToString(nLevel));
   SendDebugMessage("Quest XP percentage modifier : "+FloatToString(fMod));


   switch (nTier)
   {
      case 1: fXP = QUEST_XP_T1; break;
      case 2: fXP = QUEST_XP_T2; break;
      case 3: fXP = QUEST_XP_T3; break;
      case 4: fXP = QUEST_XP_T4; break;
   }

   SendDebugMessage("Quest base XP: "+FloatToString(fXP));

   fXP = fXP * fMod;

   SendDebugMessage("Quest XP level adjusted: "+FloatToString(fXP));

   GiveXPToPC(oPC, fXP);
}

// get xp amount by level
int GetXPFromLevel(int nLevel)
{
   int nXP = (((nLevel - 1) * nLevel) /2) * 1000;
   return nXP;
}

float GetPartyXPValue(object oCreature, int bAmbush, float fAverageLevel, int iTotalSize)
{
// If the CR is 0.0, then assume this is not a kill and do not do any XP related thingies.
   float fCR = GetChallengeRating(OBJECT_SELF);
   int iRoundedXP; float fXP;

// if tagged no xp just return 0 early
   if (GetLocalInt(oCreature, "no_xp") == 1) return 0.0;

   if (fCR <= 0.0) {return 0.0;}
   else if (fCR <= 1.0/8.0) {fXP = BASE_XP + 2.0;}
   else if (fCR <= 1.0/6.0) {fXP = BASE_XP + 3.0;}
   else if (fCR <= 1.0/4.0) {fXP = BASE_XP + 4.0;}
   else if (fCR <= 1.0/3.0) {fXP = BASE_XP + 5.0;}
   else if (fCR <= 1.0/2.0) {fXP = BASE_XP + 6.0;}
   else if (fCR <= 1.0) {fXP = BASE_XP + 12.0;}
   else if (fCR <= 2.0) {fXP = BASE_XP + 20.0;}
   else if (fCR <= 3.0) {fXP = BASE_XP + 28.0;}
   else if (fCR <= 4.0) {fXP = BASE_XP + 36.0;}
   else if (fCR <= 5.0) {fXP = BASE_XP + 44.0;}
   else if (fCR <= 6.0) {fXP = BASE_XP + 52.0;}
   else if (fCR <= 7.0) {fXP = BASE_XP + 60.0;}
   else if (fCR <= 8.0) {fXP = BASE_XP + 66.0;}
   else if (fCR <= 9.0) {fXP = BASE_XP + 72.0;}
   else if (fCR <= 10.0) {fXP = BASE_XP + 80.0;}
   else if (fCR <= 11.0) {fXP = BASE_XP + 88.0;}
   else if (fCR <= 12.0) {fXP = BASE_XP + 96.0;}
   else if (fCR <= 13.0) {fXP = BASE_XP + 104.0;}
   else if (fCR <= 14.0) {fXP = BASE_XP + 112.0;}
   else if (fCR <= 15.0) {fXP = BASE_XP + 120.0;}
   else if (fCR <= 16.0) {fXP = BASE_XP + 128.0;}
   else if (fCR <= 17.0) {fXP = BASE_XP + 136.0;}
   else if (fCR > 17.0) {fXP = BASE_XP + 144.0;}
   else {return 0.0;}

   if (fXP > 0.0)
   {
// ambushes only give 1/3 xp
       if (bAmbush) fXP = fXP/3.0;

       if (fAverageLevel < 1.0) fAverageLevel = 1.0; //failsafe if party average level was 0 or less

       float fTotalSize = IntToFloat(iTotalSize);
       if (fTotalSize < 1.0) fTotalSize = 1.0; //failsafe is party total size was 0 or less

       float fPartyMod = PARTY_SIZE_BASE_MOD/(PARTY_SIZE+(fTotalSize*PARTY_SIZE));

       SendDebugMessage("Party XP mod: "+FloatToString(fPartyMod));
       SendDebugMessage("fCR: "+FloatToString(fCR));
       SendDebugMessage("fXP: "+FloatToString(fXP));

       fXP = (fXP / fAverageLevel) * fPartyMod;

       iRoundedXP = Round(fXP);

    // Cap the xp
       if (fXP > XP_MAX) fXP = XP_MAX;
   }

   if (iRoundedXP == 0) fXP = 0.0;
   SendDebugMessage("fXP (modified by average level and party, then rounded): "+FloatToString(fXP));
   return fXP;
}
//------------------------------  END INTERNAL FUNCTIONS  -----------------------------------



// ********************************  DEFINITIONS  ******************************************


//void main(){}
