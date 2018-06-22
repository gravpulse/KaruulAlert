local addonInfo, private = ...

if private.helpIndex == nil then
	private.helpIndex = {
		"Intro",
		"Getting Started",
		"Configuration Screen",
		"Set Info",
		"Alert Info",
		"Trigger Info",
		"Trigger Conditions",
		"Image Settings",
		"Text Settings",
		"Timer Settings",
		"Menu",
		"Command Line"
	}
end

if private.helpTopic == nil then
	private.helpTopic = {} --{label = "", text = ""}
	local helpIndex = private.helpIndex  
	local helpTopic = private.helpTopic
	
	helpTopic[helpIndex[1]] = {
		{
			label = "Intro", 
			text = "Inspired by WoW's Power Auras this is a fully configurable alerting system. Track what you want how you want. Setup alerts for such things as...\n\n- A debuff you want to keep up on your target\n- Your focus is low on life\n- An ability just came off cooldown\n- You are running low on mana\n- much much more...\n\nPlease read the [[Getting Started|Getting Started]] section to learn how you can set up your own alerts."
		}
	}
	helpTopic[helpIndex[2]] = {
		{
			label = "Getting Started", 
			text = "As KaruulAlert is completely customizable it needs to know a little about your character before you start. So the first thing you should do is open the [[Configuration Screen|configuration screen]] and enable the ability scanner. This will now start building the list of buffs and abilities for you to set alerts for.\n\n1. Open configuration (/karuulalert)\n2. Check the Enable Ability Scanner check box at the lower right of configuration the screen\n\nAt this point you will have a good amount of items to choose from but to get the full list of what you can do play around a little. Switch roles, buff up, click on random players (load their buffs too). Once done disable the ability scanner to save resources.\n\nNow you should have all you need to get going.\n\nFirst stop Name, what do you want to call this alert you are making? After that it's just a matter of checking off what you want to track, typing in the ability or buff and choosing what your alert will look like.\n\n1. Open configuration (/karuulalert)\n2. Enter a Name for your alert\n3. Select Buff, Ability, Resource, or Casting\n4. Enter the name of the buff/ability or select the resource.\n5. Select the who the alert will look at\n6. Select when you want to be notified\n7. Customize the alert appearance\n8. Click Save\n\nYou now have an alert for your gaming pleasure."
		}
	}
	helpTopic[helpIndex[3]] = {
		{
			label = "Configuration Screen", 
			text = "The configuration screen consists of 7 major sections that are used to setup and maintain alerts."
		},
		{
			label = "Set Info", 
			text = "This section contains everything needed to manage alert sets. Alert sets are a collection of alerts that will be displayed on the screen. See [[Set Info|here]] for more information."
		},
		{
			label = "Alert Info", 
			text = "This section is used for general information about the alert you are setting up. Mainly the alert name and if it is active or not. See [[Alert Info|here]] for more information."
		},
		{
			label = "Trigger Info", 
			text = "This section is used to setup what you want your alert trigger off of. It can be as general as a spell being cast or as specific as a certain Buff with a length of 10seconds cast by me. See [[Trigger Info|here]] for more information."
		},
		{
			label = "Trigger Conditions", 
			text = "This section is used select the conditions that must be met for the alert to be activated. Again this can vary greatly and could be as simple as an Ability is ready to use or as complex as a Buff that has 3 stacks is active on your target in combat only. See [[Trigger Conditions|here]] for more information."
		},
		{
			label = "Image Settings", 
			text = "This section is used to setup if or how the Alert will display an image when triggered. Images can range from the default system icons for a given Buff or Ability to one of the provided sample images to your own custom image. See [[Image Settings|here]] for more information."
		},
		{
			label = "Text Settings", 
			text = "This section is used to setup how any text will be displayed when the Alert is triggered. You can setup such things as if there is any custom text displayed, where it will appear in the alert and what the font will look like. See [[Text Settings|here]] for more information."
		},
		{
			label = "Timer Settings", 
			text = "This section is used to setup if or how the Alert will display a timer when triggered. Timers can take the form of a countdown timer that counts down while an alert is active or a warning timer that gives you a countdown before the Alert is ready to trigger. See [[Timer Settings|here]] for more information."
		}
	}
	helpTopic[helpIndex[4]] = {
		{
			label = "Set Info", 
			text = "There are currently 2 types of alert sets available. They are Sets and Sub Sets. You can have a maximum of 20 Sets and 10 Sub Sets. Sets correspond to the 20 roles your character can have. Sub Sets are freeform and can be used as desired. You can have up to 1 Set and 1 Sub Set active at any given time. Common uses could be to setup a Set for your class base alerts and a Sub Set for your PvP alerts. You could then have your PvP alerts displayed regardless of what role you currently had active.\n\nYou can change between active set in one of two ways.\n\n- Via config tool, simply select the set you want and exit the tool. Note if you exit the config tool with a set selected the active set will be changed to this set and the active sub set will remain unchanged and likewise if you exit with a sub set selected the active sub set will be changed to this set and the active set will remain unchanged.\n- Via command prompt type [[Command Line/set|/karuulalert set={number}]] for set and [[Command Line/subset|/karuulalert subset={number}]] for sub sets"
		},
		{
			label = "Set Navigation Controls", 
			text = "This is a set of 3 items that let you browse through your sets. The left and right arrow buttons are used to move through available set while the title label will display the identifier of the set you currently have active."
		},
		{
			label = "Alert List", 
			text = "This is the list of alerts that are currently associated with the loaded set. You can click on an alert in this list to select it or double click the alert to load it for editing.\nRightclicking an alert will display a context menu which allows you to:\n- Move or copy an alert to a different set or subset.\n- Share an alert with another online player that also uses KaruulAlert.\n- [[Menu/Export Alert|Export]] an alert, allowing it to be placed on the clipboard."
		},
		{
			label = "Edit Button", 
			text = "This button will load the selected alert for editing. Note that alerts can also be double-clicked to edit them directly."
		},
		{
			label = "Edit Layout Button", 
			text = "This button will hide the configuration screen and display the edit layout screen and all the alerts in the current set. Doing this will allow you to drag the alerts around the screen for easy positioning and screen setup."
		}
	}

	helpTopic[helpIndex[5]] = {
		{
			label = "Alert Info", 
			text = "This section of the configuration screen consists of settings that relate to the alert as a whole."
		},
		{
			label = "Name Edit Box - (Required)", 
			text = "The name edit box is used to enter a meaningful identification for the alert. This name will appear in the alert list."
		},
		{
			label = "Layer Edit Box - (Optional)", 
			text = "This edit box will take a value from 1 to 40 and is used to set the relative layer of the alert compared to other alerts. A layer of 1 will be drawn first so a layer of 2 will appear on top of a layer 1."
		},
		{
			label = "Disable Alert Checkbox - (Optional)", 
			text = "Checking this box will disable the alert and prevent it from being processed or displayed. This would be used if you wanted to temporarily not so a given alert but did not want to delete the alert altogether."
		}
	}
	helpTopic[helpIndex[6]] = {
		{
			label = "Trigger Info", 
			text = "This section contains controls used to setup what you want your trigger to be. This section is where you determine what the system will be looking at to determine if an alert should be shown. This section is dynamic and more or less information can be provided depending on choices you make and how specific you want to be.\n\nNote that afer you configure the trigger info, you can also set up [[Trigger Conditions|Trigger Conditions]] to determine when exactly an alert will be triggered."
		},
		{
			label = "Alert Type Toggle - (Required)", 
			text = "This control is a list of what type of items you can track and currently has 4 options.\n\nThe Buff option is used when you want to track any effect that would appear in the list of buffs on the screen and can include positive(buff) and negative(debuff) effects.\n\nThe Ability option is used when you want to track abilities, spells, talents that generally speaking you need to activate. Usually abilities will be seen on the screen in your action bars.\n\nThe Resource option is used when you want to track resources such as health, mana, combo point, etc.\n\nThe Casting option is used when you want to track spells being cast or abilities being used, basically anything that causes a castbar."
		},
		{
			label = "Buff Edit Box - (Buff: Required)", 
			text = "In this box you will enter the name of the Buff you wish to track. Buffs are case sensitive. As you begin to type in this field a list of possible suggestions are displayed based on what you have entered. When you see the item you want you can double click it in the dropdown to auto complete what you are typing.\n\nAs there are often a number of buffs that provide the same effect this field will also allow you to enter a comma separated list of buffs. (Buff1,Buff2,Buff3) If any of the buffs in the list are found the alert will be true."
		},
		{
			label = "Buff Length Edit Box - (Buff: Optional)", 
			text = "In most cases this field will be left empty. It was put in for the special cases where there are two or more buffs that have the same name and only differ in how long they last. If you are tracking one of those buffs you can simply put in the duration of the buff you want to track."
		},
		{
			label = "Self Cast Only Checkbox - (Buff: Optional)", 
			text = "Checking this box will further narrow down the buff you are tracking and will only track buffs caused by you."
		},
		{
			label = "Ability Edit Box - (Ability: Required/Casting: Optional)", 
			text = "In this box you will enter the name of the Ability you wish to track. Abilities are case sensitive. As you begin to type in this field a list of possible suggestions are displayed based on what you have entered. When you see the item you want you can double click it in the dropdown to auto complete what you are typing.\n\nIn the case of Casting, if this field is left blank you will be tracking any casting and if filled in you will only be tracking if a specific spell/ability is being cast."
		},
		{
			label = "Resource Toggle - (Resource: Required)", 
			text = "This is a list of available resources that can be tracked. Simply check the one you wish to use."
		}
	}
	helpTopic[helpIndex[7]] = {
		{
			label = "Trigger Conditions", 
			text = "This section contains controls to setup the conditions that must be met for the alert to be triggered. As the [[Trigger Info|Trigger Info]] section was what we are looking at, this section is the conditions of what we are looking at."
		},
		{
			label = "Unit Toggle - (Buff/Resource/Casting: Required)", 
			text = "This control is used to select the unit you want to check for a given trigger. Checking <b>Player</b> will check you for the buff, resource or casting, checking Target will check your target and so on. You will note that this option is not currently used for Ability. At the present time abilities can only be tracked on the player and as such if Ability is chosen the unit will be set to Player internally."
		},
		{
			label = "Relation Toggle - (Buff/Resource/Casting: Optional)", 
			text = "This control is used to select the relationship of the unit to you. Selecting Friend will cause the alert to only trigger if the unit is currently friendly to you. Selecting Foe will cause the alert to only trigger if the unit is currently hostile to you. Selecting neither option will allow the alert to be triggered regardless of the units current relationship to you."
		},
		{
			label = "Active/Missing Toggle - (Buff: Required)", 
			text = "This control is used to select the state the buff must be in for the alert to trigger. If set to Active the alert will trigger only when the buff is present and likewise if set to Missing the alert will trigger only when the buff is not present."
		},
		{
			label = "Stacks Edit Box - (Buff: Optional)", 
			text = "This field is used to enter the number of stacks that are needed for a Buff to be considered active. As some buffs can be applied multiple times the stacks option can be used to specify how many times the buff needs to be applied. If left blank only one application of a buff will trigger the alert if set to a number greater than 1 the buff will need to be applied that number of times.\n\nPlease note that stack apply separately from each source. So if you apply a buff and a fellow party member applies the same buff the stacks will still be 1 as they are considered 2 separate buffs."
		},
		{
			label = "Ready/Cooldown Toggle - (Ability: Required)", 
			text = "This control is used to select the state the ability must be in for the alert to trigger. If set to Ready the alert will only trigger if the ability is available to be used. If set to Cooldown the alert will only trigger if the ability is not currently available to be used. In most cases this will be caused by the ability being on cooldown after just being used but is some cases a lack of resources can also cause an ability to be unavailable."
		},
		{
			label = "Above/Below/Range Toggle - (Resource: Required)", 
			text = "This control is used in conjunction with the Value Edit Box and sets how the value should be handled.\n\nIf Above is selected the alert will trigger if the current resource total is greater than or equal to the value set in the Value Edit Box.\n\nIf Below is selected the alert will trigger if the current resource total is less than the value set in the Value Edit Box.\n\nIf Range is selected the alert will trigger if the current resource total falls within the range set in the Value Edit Box."
		},
		{
			label = "Value Edit Box - (Resource: Required)", 
			text = "This field is used in conjunction with the Above/Below/Range Toggle and is the value that will be used to evaluate the current state of the resource.\n\nIf Above or Below are selected then a value such as 30% or 1529 can be entered in this field. To compare against an exact value you would put in a number such as 1529. To compare against a percentage you would just put the % after the value you enter like 30%.\n\nIf Range is selected values such as 290-310, 50-75% or 3 can be entered. Range must always be entered as low to high with no spaces. If percentage is desired the % must appear after the range entered. Range can also be used to enter an exact value such as 5. If a single value is entered it effectively becomes 5-5. Entering an exact value is most useful for Combo Point where you might want to trigger a different alert for each point but not want to have them all up at the same time."
		},
		{
			label = "Combat Only Checkbox - (Optional)", 
			text = "Checking this box will make the alert only able to show while you are in combat. This is useful when you setup combat centric alerts that you don't want or need to see while you are not in combat."
		}
	}
	helpTopic[helpIndex[8]] = {
		{
			label = "Image Settings", 
			text = "This section contains controls used to setup the graphical portion of the alert. Using these controls you will be able to set what the image that is displayed is, how big it is or if it is even visible at all."
		},
		{
			label = "Image Selection Box", 
			text = "This box will show you a preview of the image that will be displayed when your alert is triggered. Also if none of the other image sources are selected this box will have left and right arrows that will allow you to select from one of the provided sample images to display when your alert is triggered."
		},
		{
			label = "Use Default Image Checkbox", 
			text = "If the Buff or Ability entered in the Trigger Info section is known the Use Default Image Checkbox will appear in the top of the Image Selection Box. Checking this box will use the standard system icon for the triggered Buff or Ability. In the case of using a Buff list the default icon from the first item in the list will be used."
		},
		{
			label = "Custom Edit Box", 
			text = "If you wish to display your own custom image instead of one of the system images you can fill in this box. Currently only PNG and TGA image formats are supported and if using TGA only uncompressed TGAs can be used.\n\nTo load custom images:\n\n1. Place the PNG or TGA image file in the KaruulAlert\\custom folder.\n2. Type the filename with extension into the Custom Edit Box.\n\nIf done correctly the image should be previewed in the image Selection Box."
		},
		{
			label = "X & Y Edit Boxes", 
			text = "These fields will display the current screen position of your alert. Normally you will not need to edit these fields as you will be able to edit the alerts screen position using the edit layout button. However if desired these fields can be used to fine tune your alert position."
		},
		{
			label = "Scale Edit Box", 
			text = "This field is used to set the size of the image being displayed for your alert. It defaults to 1 which corresponds to the standard size of the image. Setting the scale to a number other than 1 will multiply the image by that number. So for larger images you would use a number greater than 1 and for smaller images you would use a number less than 1 for example 0.5."
		},
		{
			label = "Opacity Edit Box", 
			text = "This field is used to set how see through your image is. A value of 100 is 100% opaque or completely solid. A value less than 100 would be less opaque and therefor more transparent. In some cases you might not want to see the image at all. To do that you simply set the opacity to 0 and then the image will be completely invisible."
		}
	}
	helpTopic[helpIndex[9]] = {
		{
			label = "Text Settings", 
			text = "This section contains controls used to setup custom alert text as well as the font used when displaying both the custom text and alert timers."
		},
		{
			label = "Text Edit Box", 
			text = "This field can be used to add custom text to the alert when displayed. If filled in the text will be shown on top of the alert image that has been selected when active. For text only alerts simply set the image opacity to 0 and then only the text will be displayed."
		},
		{
			label = "Opacity Edit Box", 
			text = "This field is used to set how see through your text is. A value of 100 is 100% opaque or completely solid. A value less than 100 would be less opaque and therefor more transparent. This opacity applies to all text on the alert so therefore both the custom text and timer will be affected by this setting."
		},
		{
			label = "Size Edit Box", 
			text = "This field is used to select the font size of the custom text."
		},
		{
			label = "Position Toggles", 
			text = "These two controls are used to set where the custom text will be anchored on the image. Setting these controls to Outside and Top will cause the custom text to appear above the image in the alert while selecting Inside and Top will cause the custom text to appear on the image towards the top. Inside and Outside are used in conjunction with the Top, Bottom, Left and Right options. If Center is selected however the Inside and Outside options are ignored and the custom text will just be positioned in the center of the image."
		},
		{
			label = "Font Edit Box", 
			text = "This field can be used if you wish to use your own custom font instead of the default system one.\n\nTo load custom fonts:\n\n1. Place the TTF file in the KaruulAlert\\custom folder.\n2. Type the filename with extension into the Font Edit Box."
		},
		{
			label = "Color Controls", 
			text = "This set of controls is used to set the color of the text that will appear on your alert. The box next to the Color: label is a preview of the color you currently have selected. Using the R/G/B sliders will set the amount of each color that will be used. The actual color amount will be displayed in the R/G/B Edit Boxes and can be manually edited for fine tuning."
		}
	}
	helpTopic[helpIndex[10]] = {
		{
			label = "Timer Settings", 
			text = "This set of controls allows you to enable or disable alert timers and setup when and how they show up."
		},
		{
			label = "Timer Checkbox", 
			text = "This checkbox will appear when the selected trigger has the ability to have a duration. Checking this box will cause a timer to be displayed with the alert when it is triggered and count down the duration of the triggered item."
		},
		{
			label = "Warning Checkbox", 
			text = "This checkbox will appear when the selected trigger has the ability to have a duration. Checking this box will cause the alert to be shown before it would actually be triggered. For the display time before the alert should actually be triggered a countdown will be show giving a warning to the impending trigger."
		},
		{
			label = "Size Edit Box", 
			text = "This field is used to select the font size of the timer or warning."
		},
		{
			label = "Position Toggles", 
			text = "These two controls are used to set where the timer or warning will be anchored on the image. Setting these controls to Outside and Top will cause the timer or warning to appear above the image in the alert while selecting Inside and Top will cause the timer or warning to appear on the image towards the top. Inside and Outside are used in conjunction with the Top, Bottom, Left and Right options. If Center is selected however the Inside and Outside options are ignored and the timer or warning will just be positioned in the center of the image."
		},
		{
			label = "Length Edit Box - (Warning Only)", 
			text = "This field will default to 5 but can be modified as desired. The number specified is the number of seconds the warning image will be displayed before the actual alert is triggered."
		}
	}
	helpTopic[helpIndex[11]] = {
		{
			label = "Menu", 
			text = "The menu system provides access to import/export functionality via the File menu and general information and addon descriptions via the Help menu."
		},
		{
			label = "Import Alert", 
			text = "Selecting this item in the File menu will bring up the Import Alert screen. This screen can be used to import a single alert into the currently active set.\n\nTo import the alert you simply need to paste the desired alert string into the Edit Box and then click the import Button. Clicking the cancel button will exit the Import Alert Screen without importing an alert."
		},
		{
			label = "Import Set", 
			text = "Selecting this item in the File menu will bring up the Import Set screen. This screen can be used to import multiple alerts into the currently active set.\n\nTo import the set you simply need to paste the desired alert set string into the Edit Box and then click the import Button. Clicking the cancel button will exit the Import Set Screen without importing any alerts."
		},
		{
			label = "Export Alert", 
			text = "Selecting this item in the File menu will bring up the Export Alert screen. This screen can be used to export the currently selected alert from the currently active set.\n\nTo export an alert you simply need to select an alert from the list of alerts and go to File->Export Alert. When the Export Alert screen comes up the edit box will have the alert string in it. Simply select the entire string and copy it. You can then paste it to a text document for safe keeping or post it on the internet or anywhere else if you want to share it with others. Clicking the cancel button will exit the Export Alert Screen when you are done."
		},
		{
			label = "Export Set", 
			text = "Selecting this item in the File menu will bring up the Export Set screen. This screen can be used to export all the alerts in the currently active set.\n\nTo export a set you simply need to go to the set you wish to export and go to File->Export Set. When the Export Set screen comes up the edit box will have the alert set string in it. Simply select the entire string and copy it. You can then paste it to a text document for safe keeping or post it on the internet or any ware else if you want to share it with others. Clicking the cancel button will exit the Export Set Screen when you are done."
		},
		{
			label = "About", 
			text = "Selecting this item in the Help menu will display a screen with basic information about the addon."
		},
		{
			label = "Contents", 
			text = "Selecting this item from the Help menu will bring up the information found in this document."
		}
	}
	helpTopic[helpIndex[12]] = {
		{
			label = "Command Line", 
			text = "As with most addons there are a few slash commands you can use to get around in Karuul Alert."
		},
		{
			label = "/karuulalert or /kalert", 
			text = "These commands can be used alone to bring up the configuration screen or in conjunction with sub commands to do other things. Proper usage for sub commands is /karuulalert {command}"
		},
		{
			anchor = "set",
			label = "set={number|auto}", 
			text = "This command is used to set the currently active alert set. Possible values for {number} are 1-20. Alternatively, you can use the special value \"auto\" and the active set will automatically switch when you change role.\n\nUsage:\n/karuulalert set=1\n/karuulalert set=auto"
		},
		{
			anchor = "subset",
			label = "subset={number}", 
			text = "This command is used to set the currently active alert sub set. Possible values for {number} are 0-10. If 0 is passed it will disable displaying sub set alerts, any other number will load that alert set.\n\nUsage: /karuulalert subset=8"
		},
		{
			label = "help", 
			text = "This command will display the information found in this document.\n\nUsage: /karuulalert help"
		},
		{
			label = "debug", 
			text = "This command will display additional system information.\n\nUsage: /karuulalert debug"
		}
	}
	
end