// Uh oh. I don't think github doesn't recognize .hxc files as Haxe. I'm just gonna rename this to a .hx file temporarily.

import funkin.Highscore;
import funkin.play.PlayState;
import funkin.modding.module.Module;
import funkin.modding.events.ScriptEvent;
import funkin.Preferences;

import flixel.FlxState;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;

/**
 * A simple info bar, mimicking the codename engine version...
 * Well, minus the ranks, plus the combo breaks (not misses), following the current accuracy system,
 * made by a beginner, logic referenced from this https://gamebanana.com/mods/510941 (by Raltyro),
 * 
 * ...
 * 
 * Just know that if you're an experienced programmer, try to fix this mess that i made. -- Triz Game (aaaaaaaaaaaaaaaaaaa-)
 * 
 * (god, i hate having to add ; to almost every line.)
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

  var last_comboBreaks:Int = 0;
  var last_combo:Int = 0;
  var last_tnh:Int = 0;
  var miss_text:FlxText;
  var acc_text:FlxText;

  /**
   * Traces on player hit. Useful for debugging.
   * @param text Self-explanitory.
   */
  function traceOnPlayerNoteHit(text:Str) {
    if (Highscore.tallies.totalNotesHit > last_tnh) {
      trace(text);
      last_tnh = Highscore.tallies.totalNotesHit;
    }
  }
  
  /**
   * Creates the text. The logic was stolen from the score text lmao.
   * @param cur_state checks for the current state, curState broke somehow.
   */
  function createText(cur_state:PlayState) {
    infoBarYPos = (Preferences.downscroll) ? FlxG.height * 0.1 : FlxG.height * 0.9; // this is the math they calculated to place the score text's y pos
    miss_text = new FlxText(FlxG.width / 2 - 280, infoBarYPos + 30, 0, 'Combo Breaks: 0 (?)', 16);
    acc_text = new FlxText(FlxG.width / 2 - 50, infoBarYPos + 30, 0, 'Accuracy: N/A%', 16);
    miss_text.setFormat(Paths.font('vcr.ttf'), 16, 0xFFFFFFFF, 'CENTER' /**i have no idea how i do this, pls help me**/, FlxTextBorderStyle.OUTLINE, 0xFF000000);
    acc_text.setFormat(Paths.font('vcr.ttf'), 16, 0xFFFFFFFF, 'CENTER' /**i have no idea how i do this, pls help me**/, FlxTextBorderStyle.OUTLINE, 0xFF000000);
    miss_text.scrollFactor.set();
    acc_text.scrollFactor.set();
    miss_text.zIndex = 802;
    acc_text.zIndex = 802;
    miss_text.cameras = [cur_state.camHUD];
    acc_text.cameras = [cur_state.camHUD];
    cur_state.add(miss_text);
    cur_state.add(acc_text);
    trace('Infobar >>> Something has been created!');
  }

  /**
   * Returns a respective "miss rank" to the text.
   * @param comboBreaks Self-explanitory.
   */
  function missInfo(comboBreaks:Int) {
    if (comboBreaks < 1 && Highscore.tallies.good < 1) return ' (PFC)';
    else if (comboBreaks < 1) return ' (GFC)';
    else if (comboBreaks < 10) return ' (SDCB)';
    else return '';
  }
  
  /**
   * Resets the text. Self-explanitory.
   */
  function resetText() {
    hold_misses = 0;
    accuracy = 0.0;
    tallyScore = 0;
    maxTallyScore = 0;
    /**
     * Huh? oh yeah. 
     * Since the resets happens not only on a song restart, but also during state changes (see below),
     * Funkin decides to throw an error if it happens outside of PlayState.
     * Since i don't know what to do with it tho, i just put it in a try {} catch () {} function. (beginner moment)
     */
    try {
      miss_text.text = 'Combo Breaks: 0 (?)';
      acc_text.text = 'Accuracy: N/A%';
    } catch (e:Dynamic) {
      trace('Infobar >>> An error has occured! [' + e + ']');
    }
  }
  
  /**
   * Calculates the judgements, accuracy, and stuff
   * This stumped me for a while lol.
   */
  function calcTallyAndUpdateText() {
    tallyScore = (Highscore.tallies.sick + Highscore.tallies.good - Highscore.tallies.missed);
    maxTallyScore = Highscore.tallies.totalNotesHit + Highscore.tallies.missed;
    comboBreaks = Highscore.tallies.bad + Highscore.tallies.shit + hold_misses + Highscore.tallies.missed; 
    
    if (maxTallyScore >= 1) {
      if (Highscore.tallies.combo < last_combo && comboBreaks <= last_comboBreaks) hold_misses += 1;
      // Again, this stumped me for a while. I wonder why... (Hint: the line you're looking at rn.)
      
      accuracy = ((tallyScore / maxTallyScore) < 0) ? 0 : (tallyScore / maxTallyScore);
      miss_text.text = 'Combo Breaks: ' + (comboBreaks) + missInfo(comboBreaks);
      acc_text.text = 'Accuracy: '+ FlxMath.roundDecimal(accuracy * 100, 2) +'%';
    }
    last_comboBreaks = comboBreaks;
    last_combo = Highscore.tallies.combo;
  }

  /**
   * From here, it's just override functions. I don't need to explain them.
   */
  
  override function onStateChangeBegin(state:StateChangeScriptEvent) {
    trace('Infobar >>> State changed! ' + state);
    resetText();
  }
  
  override function onSongLoaded(event:SongLoadScriptEvent) {
    super.onSongLoaded(event);
    
    var state:PlayState = PlayState.instance;
    createText(state);
    resetText();
  }

  override function onDestroy(event:ScriptEvent) {
    if (miss_text != null) miss_text.destroy();
    if (acc_text != null) acc_text.destroy();
  }

  override function onUpdate(event:ScriptEvent):Void {
    super.onUpdate(event);
    calcTallyAndUpdateText();
  }

  override function onSongRetry(event:SongRetryEvent) {
    resetText();

    miss_text.destroy();
    acc_text.destroy();
  }
}
