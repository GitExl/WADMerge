/*
    Copyright (c) 2015, Dennis Meuwissen
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
       list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the documentation
       and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

module animatedlist;

import std.string;

import undead.stream;

import wad;
import util;
import console;
import duplicatelist;


immutable ubyte[9] NULL_BYTES9;


/**
 * An animated texture definition.
 * Animated textures cycle through textures in the order they are stored in the TEXTURE lumps.
 */
private struct AnimateDef {

    /// Type of this animation. 0 for textures, 1 for flats.
    ubyte type;

    /// The last and first texture name in this animation list to cycle inbetween.
    string textureLast;
    string textureFirst;

    /// The speed at which the texture changes, in tics.
    uint speed;

    /// The WAD this defintion belongs to.
    WAD wad;

    
    /**
     * Returns: The name of this animated texture definition.
     */
    public string getName() {
        return format("%s-%s", textureLast, textureFirst);
    }
}

/**
 * A switch texture definition.
 * Switch textures have an on and off texture.
 */
private struct SwitchesDef {

    /// The texture names to be used for the switch states.
    string textureOff;
    string textureOn;

    /// Defines the IWAD the the switch textures are a part of.
    /// 1 for shareware IWADs, 2 for shareware Doom, 3 for shareware, Doom or Doom II.
    ushort iwad;

    /// The WAD this definition belongs to.
    WAD wad;


    /**
     * Returns: The name of this switch texture definition.
     */
    public string getName() {
        return format("%s\\%s", textureOff, textureOn);
    }
}


/**
 * Holds a list of Boom style texture animations and switch texture definitions.
 *
 * See http://doomwiki.org/wiki/ANIMATED and http://doomwiki.org/wiki/SWITCHES for more
 * information about these lumps and their format.
 */
public final class AnimatedList {

    /// The animations and switches present in this list.
    private AnimateDef[] mAnimations;
    private SwitchesDef[] mSwitches;


    /**
     * Reads animated textures and switch textures from a WAD file.
     *
     * Params:
     * wad = The WAD file to read animations and switches from.
     */
    public DuplicateList readFrom(WAD wad) {
        DuplicateList dupes = new DuplicateList();

        Lump animated = wad.getLump("ANIMATED");
        if (animated !is null) {
            dupes.add(readAnimated(wad, animated.getStream()));
            animated.setIsUsed(true);
        }

        Lump switches = wad.getLump("SWITCHES");
        if (switches !is null) {
            dupes.add(readSwitches(wad, switches.getStream()));
            switches.setIsUsed(true);
        }

        return dupes;
    }

    /**
     * Writes an ANIMATED and SWITCHES lump containing the animations and switches in this list
     * to a WAD file.
     *
     * Params:
     * wad = The WAD file to add the lumps to.
     */
    public void addTo(WAD wad) {
        if (this.mAnimations.length > 0) {
            writeAnimated(wad);
        }
        if (this.mSwitches.length > 0) {
            writeSwitches(wad);
        }
    }

    private void writeAnimated(WAD wad) {
        MemoryStream animated = new MemoryStream();
        foreach (ref AnimateDef anim; this.mAnimations) {
            animated.write(anim.type);
            writePaddedString(animated, anim.textureLast, 9);
            writePaddedString(animated, anim.textureFirst, 9);
            animated.write(anim.speed);
        }

        // Write the terminating entry.
        animated.write(cast(ubyte)0xFF);
        animated.write(NULL_BYTES9);
        animated.write(NULL_BYTES9);
        animated.write(cast(uint)0);

        wad.addLump(new Lump("ANIMATED", animated.data()));
    }

    private void writeSwitches(WAD wad) {
        MemoryStream switches = new MemoryStream();
        foreach (ref SwitchesDef sw; this.mSwitches) {
            writePaddedString(switches, sw.textureOff, 9);
            writePaddedString(switches, sw.textureOn, 9);
            switches.write(sw.iwad);
        }

        // Write the terminating entry.
        switches.write(NULL_BYTES9);
        switches.write(NULL_BYTES9);
        switches.write(cast(ushort)0);

        wad.addLump(new Lump("SWITCHES", switches.data()));
    }

    private DuplicateList readAnimated(WAD wad, MemoryStream data) {
        int index;
        int animIndex = 0;

        DuplicateList dupes = new DuplicateList();

        while(1) {
            AnimateDef animated;
            
            // A type of 0xFF indicates the end of the animated list.
            data.read(animated.type);
            if (animated.type == 0xFF) {
                break;
            }

            animated.textureLast = readPaddedString(data, 9);
            animated.textureFirst = readPaddedString(data, 9);
            animated.wad = wad;
            data.read(animated.speed);

            // Do not add this animation to the list if it already exists.
            index = getAnimationIndex(animated);
            if (index > -1) {
                console.writeLine(Color.IMPORTANT, "Overwriting animated texture %s", animated.getName());
                dupes.add("animated texture", this.mAnimations[index].wad, this.mAnimations[index].getName(), index, animated.wad, animated.getName(), animIndex, false);
                this.mAnimations[index] = animated;
            } else {
                this.mAnimations ~= animated;
            }

            animIndex += 1;
        }

        return dupes;
    }

    private DuplicateList readSwitches(WAD wad, MemoryStream data) {
        SwitchesDef switches;
        int index;
        int switchIndex = 0;
    
        DuplicateList dupes = new DuplicateList();

        while(1) {
            SwitchesDef switchdef;

            switchdef.textureOff = readPaddedString(data, 9);
            switchdef.textureOn = readPaddedString(data, 9);

            // An IWAD id of 0 terminates this list.
            data.read(switchdef.iwad);
            if (switchdef.iwad == 0) {
                break;
            }

            // Overwrite existing definitions.
            index = getSwitchesIndex(switchdef);
            if (index > -1) {
                console.writeLine(Color.IMPORTANT, "Overwriting switch textures %s - %s", switchdef.textureOff, switchdef.textureOn);
                dupes.add("switch texture", this.mSwitches[index].wad, this.mSwitches[index].getName(), index, switchdef.wad, switchdef.getName(), switchIndex, false);
                this.mSwitches[index] = switchdef;
            } else {
                this.mSwitches ~= switchdef;
            }

            switchIndex += 1;
        }

        return dupes;
    }

    private int getAnimationIndex(const AnimateDef animation) {
        foreach (int index, ref AnimateDef anim; this.mAnimations) {
            if (anim.textureFirst == animation.textureFirst &&
                anim.textureLast == animation.textureLast) {
                return index;
            }
        }

        return -1;
    }

    private int getSwitchesIndex(const SwitchesDef switches) {
        foreach (int index, ref SwitchesDef switchdef; this.mSwitches) {
            if (switchdef.textureOff == switches.textureOff &&
                switchdef.textureOn == switches.textureOn) {
                return index;
            }
        }

        return -1;
    }
}
