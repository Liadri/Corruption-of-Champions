/**
 * Created by Kitteh6660. Volcanic Crag is a new endgame area with level 30 encounters.
 * Currently a Work in Progress.
 * 
 * This zone was mentioned in Glacial Rift doc.
 */

package classes.Scenes.Areas 
{
	import classes.*;
	import classes.GlobalFlags.kFLAGS;
	import classes.GlobalFlags.kGAMECLASS;
	import classes.Scenes.Areas.VolcanicCrag.*;
	import classes.Scenes.Areas.HighMountains.PhoenixScene;
	import classes.Scenes.NPCs.Etna;
	import classes.Scenes.NPCs.EtnaFollower;
	
	use namespace kGAMECLASS;
	
	public class VolcanicCrag extends BaseContent
	{
		public var behemothScene:BehemothScene = new BehemothScene();
		public var phoenixScene:PhoenixScene = new PhoenixScene();
		public var etnaScene:EtnaFollower = new EtnaFollower();
		
		public function VolcanicCrag() 
		{
		}
		
		public function exploreVolcanicCrag():void {
			flags[kFLAGS.DISCOVERED_VOLCANO_CRAG]++
			doNext(playerMenu);

			var choice:Array = [];
			var select:int;
			
			//Build choice list!
			choice[choice.length] = 0; //Behemoth
			if (kGAMECLASS.dungeons.checkPhoenixTowerClear()) choice[choice.length] = 1; //Phoenix
			if (rand(3) == 0) choice[choice.length] = 1; //Find Drake's Heart
			choice[choice.length] = 3; //Fire True Golems
			if (rand(4) == 0) choice[choice.length] = 4; //Find nothing! The rand will be removed from this once the Volcanic Crag is populated with more encounters.
			
			//DLC april fools
			if (isAprilFools() && flags[kFLAGS.DLC_APRIL_FOOLS] == 0) {
				getGame().DLCPrompt("Extreme Zones DLC", "Get the Extreme Zones DLC to be able to visit Glacial Rift and Volcanic Crag and discover the realms within!", "$4.99");
				return;
			}
			//Helia monogamy fucks
			if (flags[kFLAGS.PC_PROMISED_HEL_MONOGAMY_FUCKS] == 1 && flags[kFLAGS.HEL_RAPED_TODAY] == 0 && rand(10) == 0 && player.gender > 0 && !kGAMECLASS.helScene.followerHel()) {
				kGAMECLASS.helScene.helSexualAmbush();
				return;
			}
			//Etna
			if (flags[kFLAGS.ETNA_FOLLOWER] < 1 && flags[kFLAGS.ETNA_TALKED_ABOUT_HER] == 2 && rand(5) == 0) {
				etnaScene.repeatYandereEnc();
				return;
			}
			select = choice[rand(choice.length)];
			switch(select) {
				case 0:
					behemothScene.behemothIntro();
					break;
				case 1:
					phoenixScene.encounterPhoenix2();
					break;
				case 2:
					outputText("While you're minding your own business, you spot a flower. You walk over to it, pick it up and smell it. By Marae, it smells amazing! It looks like Drake's Heart as the legends foretold. ", true);
					inventory.takeItem(consumables.DRAKHRT, camp.returnToCampUseOneHour);
					break;
				case 3: //True Fire Golems
					outputText("As you take a stroll, from nearby cracks emerge group of golems. Looks like you have encountered some true fire golems! You ready your " + player.weaponName + " for a fight!", true);
					startCombat(new GolemsTrueFire());
					break;
				default:
					outputText("You spend one hour exploring the infernal landscape but you don't manage to find anything interesting, yet you this time you managed walk a little further inside this place than the last time.", true);
					dynStats("spe", .5);
					doNext(camp.returnToCampUseOneHour);
			}
		}
		
	}

}