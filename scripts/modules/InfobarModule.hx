/**
 * Uh oh. I don't think github doesn't recognize .hxc files as Haxe.
 * I'm just gonna rename this to a .hx file temporarily.
 * Remember to change the extension to .hxc.
 */

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
 * Well, minus the ranks, combo breaks instead of misses, following the current accuracy system,
 * made by a beginner, logic referenced from this https://github.com/Raltyro/kade-hud-fnf-vslice (by Raltyro),
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
  var screenCenter:Float = FlxG.width / 2;

  var last_comboBreaks:Int = 0;
  var last_combo:Int = 0;
  var last_tnh:Int = 0; // Debugging purposes (pls don't comment this)
  var miss_text:FlxText;
  var acc_text:FlxText;
  
  // Fun fact: I like to put stuff as a new function so i don't get confused.
  // ...and i think you got confused.

  /**
   * Just a function only available on my scripts.
   * Please keep this. (or even better, use it.)
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
   * Creates the text. The text creation logic was stolen from the score text lmao.
   * @param cur_state Checks for the current state.
   */
  function createText(cur_state:PlayState) {
    infoBarYPos = (Preferences.downscroll) ? FlxG.height * 0.1 : FlxG.height * 0.9; // this is the math they calculated to place the score text's y pos
    miss_text = new FlxText(screenCenter - 280, infoBarYPos + 30, 0, 'Combo Breaks: 0', 16);
    miss_text.setFormat(Paths.font('vcr.ttf'), 16, 0xFFFFFFFF, 'CENTER' /**i have no idea how i do this, pls help me**/, FlxTextBorderStyle.OUTLINE, 0xFF000000);
    miss_text.scrollFactor.set();
    miss_text.zIndex = 802;
    miss_text.cameras = [cur_state.camHUD];
    cur_state.add(miss_text);
    
    acc_text = new FlxText(screenCenter - 75, infoBarYPos + 30, 0, 'Accuracy: N/A%', 16);
    acc_text.setFormat(Paths.font('vcr.ttf'), 16, 0xFFFFFFFF, 'CENTER' /**i have no idea how i do this, pls help me**/, FlxTextBorderStyle.OUTLINE, 0xFF000000);
    acc_text.scrollFactor.set();
    acc_text.zIndex = 802;
    acc_text.cameras = [cur_state.camHUD];
    cur_state.add(acc_text);
    traceTG('The texts are created!');
  }

  /**
   * Returns a respective "accuracy rank" to the text.
   * There's only PFC and GFC since bads and shits are considered misses.
   * @param accCheck Checks the current accuracy. (I don't know why, but it's better.)
   */
  function accInfo(accCheck:Int) {
    if (accCheck == 1 && Highscore.tallies.good < 1) return 'PFC%';
    else if (accCheck == 1) return 'GFC%';
    else return FlxMath.roundDecimal(accuracy * 100, 2) +'%';
  }

  /**
   * Moves the accuracy text's X position slightly.
   * ...hey, i want it to look good.
   * @param accCheck Checks the current accuracy.
   */
  function changeAccTextX(accCheck:Float) {
    // First, create a variable for one, two, and three digits of comboBreaks
    // (four digits? maybe)
    var one_digit = 70;
    var two_digit = 65;
    var three_digit = 60;

    // Then checks if the player has hit (or missed) a note yet.
    if (comboBreaks == 0 && Highscore.tallies.totalNotesHit == 0) return;

    // And now it's position change galore (i hope you can read this lol)
    if (comboBreaks < 9) {
      if ((accCheck * 100) % 1 == 0) acc_text.setPosition(screenCenter - one_digit, infoBarYPos + 30);
      else acc_text.setPosition(screenCenter - one_digit - 16, infoBarYPos + 30);
    }
    else if (comboBreaks < 99) {
      if ((accCheck * 100) % 1 == 0) acc_text.setPosition(screenCenter - two_digit, infoBarYPos + 30);
      else acc_text.setPosition(screenCenter - two_digit - 16, infoBarYPos + 30);
    }    
    else {
      if ((accCheck * 100) % 1 == 0) acc_text.setPosition(screenCenter - three_digit, infoBarYPos + 30);
      else acc_text.setPosition(screenCenter - three_digit - 16, infoBarYPos + 30);
    }
    traceOnPlayerNoteHit('accCheck='+accCheck); // Debugging purposes
  }
  
  /**
   * Resets the text.
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
      miss_text.text = 'Combo Breaks: 0';
      acc_text.text = 'Accuracy: N/A%';
    } catch (e:Dynamic) {
      traceTG('An error has occured! ['+e+']');
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
      miss_text.text = 'Combo Breaks: ' + (comboBreaks);
      acc_text.text = 'Accuracy: ' + accInfo(accuracy);
    }
    last_comboBreaks = comboBreaks;
    last_combo = Highscore.tallies.combo;
  }

  // From here, it's just override functions. I don't need to explain them.
  override function onStateChangeBegin(state:StateChangeScriptEvent) {
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
    changeAccTextX(FlxMath.roundDecimal(accuracy, 4));
  }

  override function onSongRetry(event:SongRetryEvent) {
    resetText();
    miss_text.destroy();
    acc_text.destroy();
  }
}
