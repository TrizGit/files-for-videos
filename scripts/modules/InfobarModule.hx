/**
 * Uh oh. I don't think github doesn't recognize .hxc files as Haxe.
 * I'm just gonna rename this to a .hx file temporarily.
 * Remember to change the extension to .hxc, or just download the binary file.
 */

import funkin.Highscore;
import funkin.play.PlayState;
import funkin.modding.module.Module;
import funkin.modding.events.ScriptEvent;
import funkin.Preferences;
import funkin.save.Save;

import flixel.FlxState;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.text.FlxTextFormat;
import flixel.util.FlxColor;

/**
 * A simple info bar, (actually) mimicking codename engine (this time)...
 * Well, it's named combo breaks instead of misses, following the current accuracy system,
 * made by a beginner, logic referenced from this https://github.com/Raltyro/kade-hud-fnf-vslice (by Raltyro),
 * 
 * ...
 * 
 * Just know that if you're an experienced programmer, try to fix this mess that i made. --Triz Game (aaaaaaaaaaaaaaaaaaa-)
 * 
 * (god, i hate forgetting to add ; to almost every line.)
 */

class InfobarModule extends Module {

  function new() {
    super("InfobarModule");
  }

  var comboBreaks:Int = 0;
  var hold_misses:Int = 0;
  var accuracy:Float = 0.0;
  var tallyScore:Int = 0;
  var maxTallyScore:Int = 0;
  
  var screenCenter:Float = FlxG.width / 2; // wait, screen size is always even numbers... oh well.
  var rankInfo = null;
  var okToRun = false; // just checkin' if it's a PlayState and not any other so it doesn't throw an error.
  
  var last_comboBreaks:Int = 0;
  var last_combo:Int = 0;
  var last_tnh:Int = 0; // debugging purposes (don't comment it tho.)
  
  var miss_text:FlxText;
  var acc_text:FlxText;
  var x_offset:Int = 63; // "what's this?" | check the xChangeByLength [line 203] function, i dare you.
  
  // Fun fact: I like to put stuff as a new function so i don't get confused... and i think you got confused. Oh well.
  
  /**
   * Just a function only available on my scripts.
   * just leave this be, stop threatening it.
   */
   function traceTG(text:Str) {
     trace('TrizGit Scripts >>> ' + text);
    }
    
  /**
   * Traces on player hit. Use for debugging.
   */
   function traceOnPlayerNoteHit(text:Str) {
     if (Highscore.tallies.totalNotesHit > last_tnh) {
       traceTG(text);
       last_tnh = Highscore.tallies.totalNotesHit;
      }
  }

  /**
   * Colors the last letter of a text.
   * i hate to do this so much.
   * @param text The text. FlxText. what else?
   */
  function colorMeSurprise(text:FlxText, color:Int) {
    if (!okToRun) return;

    var textLength = text.text.length;
    // me when i put it in onUpdate: error
    text.clearFormats();
    text.addFormat(new FlxTextFormat(color), textLength - 1, textLength);
  }
    
  /**
   * Creates the text.
   * the logic "borrowed" from the score text lmao.
   * @param cur_state checks for the current state. (i dunno why i added this.)
   */
  function createText(cur_state:PlayState) {
    infoBarYPos = (Preferences.downscroll) ? FlxG.height * 0.1 : FlxG.height * 0.9; // this is the math they calculated to place the score text's y pos
    
    acc_text = new FlxText(screenCenter - 280, infoBarYPos + 30, 0, 'Accuracy: N/A% - ?', 16);
    acc_text.setFormat(Paths.font('vcr.ttf'), 16, 0xFFFFFF, 'CENTER', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    acc_text.scrollFactor.set();
    acc_text.zIndex = 802;
    acc_text.cameras = [cur_state.camHUD];
    acc_text.moves = true;
    cur_state.add(acc_text);
    
    miss_text = new FlxText(screenCenter - x_offset, infoBarYPos + 30, 0, 'Combo Breaks: 0', 16);
    miss_text.setFormat(Paths.font('vcr.ttf'), 16, 0xFFFFFF, 'CENTER', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    miss_text.scrollFactor.set();
    miss_text.zIndex = 802;
    miss_text.cameras = [cur_state.camHUD];
    cur_state.add(miss_text);
    
    traceTG('The texts are created!');
  }

  /**
   * Returns a respective "accuracy rank" to the text.
   * there's only PFC and GFC since bads and shits are considered misses.
   * @param accCheck checks the current accuracy. (idk why i added this, but uhhh... keep it.)
   */
  function accInfo(accCheck:Float) {
    if (accCheck == 1 && Highscore.tallies.good < 1)  return 'PFC%';
    else if (accCheck == 1)                           return 'GFC%';
    else return                                       FlxMath.roundDecimal(accCheck * 100, 2) +'%';
  }

  /**
   * Returns a song rank. Rank is actually based on the rank system in v-slice.
   * @param accCheck checks the current accuracy. (idk why i added this, but uhhh... keep it.)
   */
  function accRank(accCheck:Float):{rank:Str, color:Int} {
    return switch (true) { // using the switch function like an if else statement... good job me.
      case accCheck == 1.0 && Highscore.tallies.good < 1: // Perfect Gold
        {rank: 'P', color: 0xFFB619};
      case accCheck == 1.0: // Perfect
        {rank: 'P', color: 0xFF58B4};
      case accCheck >= 0.9: // Excellent
        {rank: 'E', color: 0xFDCB42};
      case accCheck >= 0.8: // Great
        {rank: 'G', color: 0xEAF6FF};
      case accCheck >= 0.6: // Good
        {rank: 'G', color: 0xEF8764};
      case accCheck < 0.6: // Shit (or Loss)
        {rank: 'L', color: 0x6044FF};
      default: // Only at the start before note hits, or maybe errors happen idk.
        {rank: '?', color: 0xFFFFFF};
    }
  }
  
  /**
   * Resets the text.
   */
  function resetText() {
    hold_misses = 0;
    accuracy = 0.0;
    tallyScore = 0;
    maxTallyScore = 0;
    try {
      miss_text.text = 'Combo Breaks: 0';
      acc_text.text = 'Accuracy: N/A% - ?';
    } catch (e:Dynamic) {
      traceTG('An error has occured! ['+e+']');
    }
  }
  
  /**
   * Calculates the judgements, accuracy, and stuff idk.
   * this stumped me for a while lol.
   */
  function calcTallyAndUpdateText() {
    tallyScore = (Highscore.tallies.sick + Highscore.tallies.good - Highscore.tallies.missed);
    maxTallyScore = Highscore.tallies.totalNotesHit + Highscore.tallies.missed;
    comboBreaks = Highscore.tallies.bad + Highscore.tallies.shit + hold_misses + Highscore.tallies.missed;
    
    if (maxTallyScore >= 1) {
      // again, this stumped me for a while. I wonder why... (Hint: this line you're looking at rn.)
      if (Highscore.tallies.combo < last_combo && comboBreaks <= last_comboBreaks) hold_misses += 1;
      
      /**
       * errors happens to the best of us...
       * update: i just learnt this thing called "Press F5 to dump the cache without restating the engine." -_-, how tf did i not notice this. 
       * oh well, i'm keeping it incased in this try function.
       */
      try {
        rankInfo = accRank(accuracy);
        accuracy = ((tallyScore / maxTallyScore) < 0) ? 0 : (tallyScore / maxTallyScore);
        miss_text.text = 'Combo Breaks: ' + (comboBreaks);
        acc_text.text = 'Accuracy: ' + accInfo(accuracy) + ' - ' + rankInfo.rank;
        colorMeSurprise(acc_text, rankInfo.color);
      } catch (e:Dynamic) {
        traceTG('An error has occured! ['+e+']');
      }
    }
    last_comboBreaks = comboBreaks;
    last_combo = Highscore.tallies.combo;
  }

  /**
   * Just visual stuff that you probably won't notice, fuuuuuuuuuu-
   */
  function xChangeByLength() {
    if (!okToRun) return;

    acc_text_math = acc_text.text.length - 17; // oh fuck you, i did what i have to do

    // my math ain't mathing, wtf
    if (comboBreaks < 10)       miss_text.x = screenCenter - x_offset + (acc_text_math * 8 - acc_text_math * 4) - 6;
    else if (comboBreaks < 100) miss_text.x = screenCenter - x_offset + (acc_text_math * 6 - acc_text_math * 4) - 10;
    else                        miss_text.x = screenCenter - x_offset - 12;

    traceOnPlayerNoteHit('\nAcc Text: ' + acc_text.text.length + ' | Miss Text: ' + miss_text.text.length + '\nThe math: ' + miss_text.x);
  }

  // From here, it's just override functions. I don't (really) need to explain them, soooooooooooooo..... reading past this is basically useless.
  override function onSongLoaded(event:SongLoadScriptEvent) {
    super.onSongLoaded(event);
    var state:PlayState = PlayState.instance;
    createText(state);
    resetText();
    okToRun = true;
  }
  
  override function onDestroy(event:ScriptEvent) {
    if (miss_text != null) miss_text.destroy();
    if (acc_text != null) acc_text.destroy();
    okToRun = false;
  }

  override function onUpdate(event:ScriptEvent):Void {
    super.onUpdate(event);
    calcTallyAndUpdateText();
    xChangeByLength();
  }

  override function onSongRetry(event:SongRetryEvent) {
    resetText();
    miss_text.destroy();
    acc_text.destroy();
  }
}
