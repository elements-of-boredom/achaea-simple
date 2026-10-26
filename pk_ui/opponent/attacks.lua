-- Attacks and class tells, maintained by hand. Seeded once from Nexus(T) triggers, LEVI's determine_class
-- and WunderSys's Class detection; the trailing comment on each line says which of them had it.
-- { pattern, classes }: the first capture is the person; classes are who could have done it.
-- acted = false: a class tell, not them acting on you. missed = true: used, but didn't connect.
-- blocked: what would have stopped this attack, beyond ATTACKED in parse_symptoms.lua. Groups: any one
--          group stops it, and everything in a group must be present. An affliction name, or a limb
--          (leftarm, rightarm, leftleg, rightleg) meaning broken, damaged or mangled.
--          e.g. blocked = { { "prone" }, { "leftarm", "rightarm" } }  -- not prone, and not both arms out
-- Help debugging: run lua5.1 -e 'dofile("opponent/attacks.lua")' from pk_ui to look for syntax issues
return {
    { [[^([\w'\-]+) connects to the .+\!$]], { "monk" } }, -- nexus(T)
    { [[^([\w'\-]+) lashes out with a straight kick at you\.$]], { "monk" }, blocked = { { "prone" } } }, -- levi+nexus(T)+wsys
    { [[^([\w'\-]+) whips .+ in a tight arc, sweeping it at your head\.$]], { "monk" } }, -- levi+nexus(T)
    { [[^Snapping \w+ leg out to its full extent, ([\w'\-]+) drives a heel into your \w+ knee\.$]], { "monk" } }, -- nexus(T)+wsys
    { [[^Lunging off \w+ back foot, ([\w'\-]+) viciously drives the end of .+ into your solar plexus\.$]], { "monk" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) spins a full rotation, bringing .+ around in a blur to crash into your torso\.$]], { "monk" } }, -- nexus(T)
    { [[^Dropping back into a low crouch, ([\w'\-]+) whips .+ at your .+ thigh\.$]], { "monk" } }, -- levi+nexus(T)+wsys
    { [[^([\w'\-]+) springs off \w+ back leg, the ball of \w+ rising foot sending stars exploding across your vision as it crashes into the side of your head.$]], { "monk" } }, -- nexus(T)
    { [[^Continuing \w+ kata, ([\w'\-]+) spins .+ in \w+ hands before driving it in a swift thrust towards your head.$]], { "monk" } }, -- nexus(T)
    { [[^([\w'\-]+) lets fly at you with a snap kick.$]], { "monk" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) balls up one fist and hammerfists you.$]], { "monk" } }, -- nexus(T)
    { [[^([\w'\-]+) launches a powerful uppercut at you.$]], { "monk" } }, -- nexus(T)
    { [[^([\w'\-]+) spins into the air and throws a whirlwind kick towards you.$]], { "monk" } }, -- nexus(T)
    { [[^([\w'\-]+) hurls himself towards you with a lightning-fast moon kick.$]], { "monk" } }, -- nexus(T)
    { [[^([\w'\-]+) forms a spear hand and stabs out at you.$]], { "monk" } }, -- nexus(T)
    { [[^([\w'\-]+) pumps out at you with a powerful side kick.$]], { "monk" } }, -- nexus(T)
    { [[^([\w'\-]+) unleashes a powerful hook towards you.$]], { "monk" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) throws \w+ palm towards your face.$]], { "monk" } }, -- nexus(T)
    { [[^([\w'\-]+) whips .+ at the side of your neck.$]], { "monk" } }, -- levi+nexus(T)+wsys
    { [[^([\w'\-]+) lashes out with a high kick at your head.$]], { "monk" } }, -- nexus(T)
    { [[^Stepping forward, ([\w'\-]+) drives .+ into your head.$]], { "monk" } }, -- nexus(T)
    { [[^([\w'\-]+) lashes out with a high kick at your \w+.$]], { "monk" } }, -- levi+nexus(T)+wsys
    { [[^([\w'\-]+) flashes .+ in front of your eyes in a blur, momentarily confusing you before slashing into your flesh.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- nexus(T)
    { [[^The blade of ([\w'\-]+) is a blur as \w+ moves forward, slicing into you.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- nexus(T)+wsys
    { [[^The blade of ([\w'\-]+) is a blur as .+ moves forward, slicing into your .+\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- levi+nexus(T)
    { [[^A look of resolve briefly crosses the face of ([\w'\-]+)\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- nexus(T)
    { [[^([\w'\-]+) swings .+ at your .+ with all .+ might\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) slashes into your .+ with .+\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- nexus(T)+wsys
    { [[^Lightning-quick, ([\w'\-]+) jabs your .+ with .+\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- levi+nexus(T)
    { [[^([\w'\-]+) swings .+ at you with all \w+ might\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) slashes into you with .+$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- nexus(T)+wsys
    { [[^Lightning-quick, ([\w'\-]+) jabs you with .+\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- nexus(T)
    { [[^([\w'\-]+) razes your aura of rebounding with .+\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- nexus(T)
    { [[^([\w'\-]+) whips .+ toward you\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) whips .+ toward your .+\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- levi+nexus(T)
    { [[^([\w'\-]+) skilfully whirls .+ toward your .+\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- nexus(T)
    { [[^([\w'\-]+) unleashes a terrible blow at your .+ with .+\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- levi+nexus(T)
    { [[^([\w'\-]+) explodes upward from a low crouch, driving .+ toward your torso\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- nexus(T)
    { [[^([\w'\-]+) whips .+ through the air in front of you, to no effect.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- levi+nexus(T)
    { [[^([\w'\-]+)'s ghazal brings sweat to your skin and tears to your eyes\.$]], { "bard" } }, -- nexus(T)
    { [[^([\w'\-]+)'s paean slams into you with all the weight of history's greatest triumphs\.$]], { "bard" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+)'s refrain leaves you gasping for breath\.$]], { "bard" } }, -- nexus(T)+wsys
    { [[^The nobility of ([\w'\-]+)'s prosodion brings misfortune unto you\.$]], { "bard" } }, -- nexus(T)
    { [[^The nomos of ([\w'\-]+) sings out as it shatters the anti-weapon field surrounding you\.$]], { "bard" } }, -- nexus(T)
    { [[^The great losses of your life weigh heavy upon your soul with ([\w'\-]+)'s elegy for the departed\.$]], { "bard" } }, -- nexus(T)
    { [[^A keening whine emanates from the rapier of ([\w'\-]+)\.$]], { "bard" }, missed = true }, -- nexus(T)
    { [[^The sinister implications of ([\w'\-]+)'s refrain plague you\.$]], { "bard" } }, -- nexus(T)
    { [[^The nomos of ([\w'\-]+) wails discordantly as it finds nothing surrounding you to destroy.$]], { "bard" } }, -- nexus(T)
    { [[^([\w'\-]+) delivers a lightning-fast strike to you with .+\.$]], { "depthswalker" } }, -- levi+nexus(T)+wsys
    { [[^([\w'\-]+) barely clips you with .+ as \w+ fumbles \w+ attack.$]], { "depthswalker" }, missed = true }, -- nexus(T)
    { [[^([\w'\-]+) utters a prayer and smites your .+ with .+\.$]], { "priest" } }, -- nexus(T)
    { [[^([\w'\-]+) utters a prayer and smites you with .+\.$]], { "priest" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) draws a steadying breath but falters soon there after\.$]], { "priest" }, missed = true }, -- nexus(T)
    { [[^"And face your penance\!" ([\w'\-]+) denounces you, hand raised in warding.$]], { "priest" } }, -- nexus(T)
    { [[^([\w'\-]+) points .+ at you and you scream in pain as your skin begins to freeze and crack\.$]], { "magi" } }, -- nexus(T)
    { [[^([\w'\-]+) lifts .+ to point at .+ and unleashes a stream of brilliant flame\.$]], { "magi" } }, -- nexus(T)
    { [[^([\w'\-]+) clicks .+ fingers and a bolt of lightning strikes from the air in a fulminous flash to transfix you\.$]], { "magi" } }, -- nexus(T)+wsys
    { [[^A single, piercing note emanates from ([\w'\-]+), a sound to set teeth on edge and glass to shattering\.$]], { "magi" } }, -- nexus(T)
    { [[^([\w'\-]+) weaves earth and water and a torrent of thick sticky mud thunders forth to roll over you and knocking you off your feet\.$]], { "magi" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) weaves fire and water as .+ directs .+ arcane might against you\.$]], { "magi" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) weaves fire and earth in a complex pattern and magma boils into existence in a bubbling tide which crashes down upon you in a wash of heat and pain\.$]], { "magi" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) attempts to transfix you, but succeeds only in curing your blindness\.$]], { "magi" } }, -- nexus(T)
    { [[^([\w'\-]+) sweeps a primordial staff over .+ head and a great wind rises, picking you up in an unnatural grasp and casting you violently about before hurling you back to the ground\.$]], { "magi" } }, -- nexus(T)+wsys
    { [[^The powers of Elemental Earth conform to the will of ([\w'\-]+), and with a thunderous roar boulders begin materialising from the air itself to hammer relentlessly at your body\.$]], { "magi" } }, -- nexus(T)
    { [[^([\w'\-]+) points .+ at you, and an intangible wave of something strikes forth to smite you\. Your bones convulse within your body, and a terrible sense of wrongness sweeps throughout your mortal shell\.$]], { "magi" } }, -- nexus(T)
    { [[^([\w'\-]+) makes no motion or word, but a roiling nausea rolls through you, a terrible dizziness and rejection as bile fills the back of your throat\.$]], { "magi" } }, -- nexus(T)+wsys
    { [[^The air thrums about ([\w'\-]+) as \w+ weaves Elemental Earth, a flurry of rocks materialising to batter and disorient you\.$]], { "magi" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) sweeps .+ over \w+ head and a great wind rises, picking you up in an unnatural grasp and casting you violently about before hurling you back to the ground\.$]], { "magi" } }, -- nexus(T)
    { [[^([\w'\-]+) stares at you, giving you the evil eye\.$]], { "apostate" } }, -- levi+nexus(T)+wsys
    { [[^A frustrated frown crosses the face of ([\w'\-]+)\.$]], { "apostate" }, missed = true }, -- nexus(T)
    { [[^([\w'\-]+) glows with an emerald hue and snaps .+ fingers at you\.$]], { "occultist" } }, -- levi+nexus(T)+wsys
    { [[^([\w'\-]+) makes a quick, sharp gesture toward you\.$]], { "occultist" } }, -- levi+nexus(T)+wsys
    { [[^([\w'\-]+) passes \w+ hand in front of you. You feel an invisible claw brush the back of your skull.$]], { "occultist" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) flings a tarot card at you which turns an ominous, sickly red before striking you in the head\.$]], { "occultist" } }, -- nexus(T)
    { [[^Orange light sparks about the digits of ([\w'\-]+) as .+ flings a card at you, the image upon it writhing until it resolves into a twisted visage crossed with a bloody knife that fills your vision\.$]], { "occultist" } }, -- nexus(T)
    { [[^With a terrible roar ([\w'\-]+) whips a colossal fist at your .+\.$]], { "earthlord" } }, -- nexus(T)+wsys
    { [[^A whip of flame coalesces in the hand of ([\w'\-]+), with which \w+ viciously lashes you\.$]], { "firelord" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) fashions a weave of flame and casts it about you, its burning tendrils writhing like living serpents to entangle you in their conflagrant grasp\.$]], { "firelord" } }, -- nexus(T)+wsys
    { [[^Pain erupts between your eyes as the hand of ([\w'\-]+) darts out like a striking snake, one finger brushing your brow for the briefest instant\. The scent of cooking meat fills your nose as your flesh cooks in an instant\.$]], { "firelord" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) reaches out and clasps your face between blazing hands, \w+ touch alone searing you to the bone and setting every muscle to spasming\.$]], { "firelord" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) quickly pricks you with .+\.$]], { "serpent" } }, -- nexus(T)
    { [[^Striking like a snake, ([\w'\-]+) follows the first attack with another\.$]], { "serpent" } }, -- levi+nexus(T)+wsys
    { [[^([\w'\-]+) misses you with .+ dirk by a hair\.$]], { "serpent" }, missed = true }, -- nexus(T)
    { [[^([\w'\-]+) sinks .+ fangs into your body and you wince in pain\.$]], { "serpent" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) fixes .+ gaze to yours and hisses a sharp command\.$]], { "serpent" } }, -- nexus(T)
    { [[^([\w'\-]+) flays away your .+ defence\.$]], { "serpent" } }, -- nexus(T)
    { [[^You are suddenly hoisted from your feet by ([\w'\-]+), who holds a noose tightly around your neck\.$]], { "serpent" } }, -- nexus(T)
    { [[^([\w'\-]+)'s blow lands upon you but is robbed of much of its impact by \w+ flawed technique\.$]], { "psion" }, missed = true }, -- nexus(T)
    { [[^A terrible weariness overcomes you as ([\w'\-]+) darts out \w+ blade and drives the tip into you just beneath your .+\.$]], { "psion" } }, -- nexus(T)
    { [[^Your .+ flops uselessly as ([\w'\-]+) severs the muscles in it with a precise blow of \w+ translucent sword\.$]], { "psion" } }, -- nexus(T)
    { [[^A sharp pain across your throat and a sudden lack of breath comes moments before you register the retreat of ([\w'\-]+), bloody dagger in hand\.$]], { "psion" } }, -- nexus(T)+wsys
    { [[^Stars explode in front of your eyes as ([\w'\-]+) smashes a translucent mace into the side of your head\.$]], { "psion" } }, -- nexus(T)+wsys
    { [[^A translucent lash coalesces in ([\w'\-]+)'s hands, firming as it gains substance beyond the incorporeal\.$]], { "psion" } }, -- nexus(T)+wsys
    { [[^A translucent mace coalesces in ([\w'\-]+)'s hands, firming as it gains substance beyond the incorporeal\.$]], { "psion" } }, -- nexus(T)
    { [[^([\w'\-]+) brings a translucent battleaxe down in a powerful overhanded blow upon you.$]], { "psion" } }, -- nexus(T)
    { [[^([\w'\-]+) delivers a series of lashes against you with a translucent lash, and your muscles grow weak, lethargy overcoming you in a rush.$]], { "psion" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) delivers a series of lashes against you with a translucent lash, and your thoughts scatter like leaves on the wind.$]], { "psion" } }, -- nexus(T)+wsys
    { [[^Pain explodes through your skull as ([\w'\-]+) brings a translucent mace around in a savage backhanded blow to your face.$]], { "psion" } }, -- nexus(T)
    { [[^([\w'\-]+) ducks low, his blade slicing into your .+.$]], { "psion" } }, -- nexus(T)
    { [[^([\w'\-]+) traces .+ the air before you, the blood upon faes knife bursting into arcane flame as it hangs in the wake of the blade's passage\.$]], { "pariah" } }, -- nexus(T)
    { [[^([\w'\-]+) traces a logograph depicting a lunging bear in the air before you, the blood upon .+ knife bursting into arcane flame as it hangs in the wake of the blade's passage.$]], { "pariah" } }, -- nexus(T)
    { [[^([\w'\-]+) traces a logograph shaped like a scarab in the air before you, the blood upon \w+ knife bursting into arcane flame as it hangs in the wake of the blade's passage.$]], { "pariah" } }, -- nexus(T)
    { [[^([\w'\-]+) raises \w+ left hand, and snaps \w+ fingers.$]], { "pariah" } }, -- nexus(T)
    { [[^([\w'\-]+) traces a logograph shaped like a skein in the air before you, the blood upon \w+ knife bursting into arcane flame as it hangs in the wake of the blade's passage.$]], { "pariah" } }, -- nexus(T)
    { [[^([\w'\-]+) traces .+, the blood upon \w+ knife bursting into arcane flame as it hangs in the wake of the blade's passage.$]], { "pariah" } }, -- nexus(T)
    { [[^([\w'\-]+) points an imperious finger at you\.$]], { "shaman" } }, -- nexus(T)+wsys
    { [[^With a quick prayer, ([\w'\-]+) expertly fashions some rope and cloth into the rough semblance of a humanoid.$]], { "shaman" } }, -- nexus(T)
    { [[^With an appraising glance at you, ([\w'\-]+) shapes the arms and legs of a rough doll.$]], { "shaman" } }, -- nexus(T)
    { [[^([\w'\-]+) glances at you while adding some facial detail to a doll.$]], { "shaman" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) looks closely at your hands and alters a Vodun doll.$]], { "shaman" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) looks at your eyes and makes some alterations to \w+ doll.$]], { "shaman" } }, -- nexus(T)+wsys
    { [[^With one hand ominously pointed towards you, ([\w'\-]+) rubs a finger over the heart of a Vodun doll.$]], { "shaman" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) laughs darkly and squints at you as \w+ adds the final touches to a Vodun doll of you.$]], { "shaman" } }, -- nexus(T)
    { [[^([\w'\-]+) gestures imperiously at you.$]], { "shaman" } }, -- nexus(T)
    { [[^([\w'\-]+) points \w+ finger at you, but nothing seems to happen.$]], { "shaman" }, missed = true }, -- nexus(T)
    { [[^([\w'\-]+) cocks back \w+ arm and throws .+ at your .+\.$]], { "sentinel" } }, -- levi+nexus(T)
    { [[^([\w'\-]+) cocks back \w+ arm and throws .+ at you\.$]], { "sentinel" } }, -- nexus(T)
    { [[^([\w'\-]+) viciously lacerates you with .+\.$]], { "sentinel" } }, -- levi+nexus(T)+wsys
    { [[^.+ flies by as ([\w'\-]+)'s poorly-aimed throw misses you.$]], { "sentinel" }, missed = true }, -- nexus(T)
    { [[^([\w'\-]+) glowers at you with a look of repressed disgust before making a slight gesture toward you\.$]], { "alchemist" } }, -- nexus(T)+wsys
    { [[^Your body locks in paralysis as a burst of arcane power floods your system, directed by ([\w'\-]+)\.$]], { "sylvan" } }, -- nexus(T)+wsys
    { [[^The thorny vines of the Viridian ([\w'\-]+) lash out and rip into your .+\.$]], { "sylvan" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) summons forth a terrible cyclone of wind, picking you up and whipping you violently against all available surfaces until your head spins and your body aches.$]], { "sylvan" } }, -- nexus(T)
    { [[^([\w'\-]+)'s many serpentine heads lunge towards your .+\.$]], { "druid" } }, -- nexus(T)
    { [[^In a furor of gnashing teeth and toxic bile, ([\w'\-]+) tears at your .+ with two of \w+ serpentine heads\.$]], { "druid" } }, -- nexus(T)
    { [[^With a synchronous, guttural rasp, ([\w'\-]+)'s many serpentine heads breathe forth wisps of rapidly condensing smoke that entangle you in a tangible web.$]], { "druid" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) sinks (?:\w+) vicious fangs deep into your body, ravaging your flesh.$]], { "druid" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) springs forwards onto you and mauls you viciously.$]], { "druid" } }, -- nexus(T)
    { [[^([\w'\-]+) springs forwards and mauls your .+.$]], { "druid" } }, -- nexus(T)
    { [[^([\w'\-]+) springs towards you, plunging \w+ deadly stinger into your body.$]], { "druid" } }, -- nexus(T)
    { [[^You double over and hack up water beneath the pitiless gaze of ([\w'\-]+)\.$]], { "waterlord" } }, -- nexus(T)+wsys
    { [[^A wave of nausea rolls over you as ([\w'\-]+) casually waves a hand in your direction\.$]], { "waterlord" } }, -- nexus(T)+wsys
    { [[^A sudden deluge of shockingly cold water drenches you, robbing you of strength by the will of ([\w'\-]+)\.$]], { "waterlord" } }, -- nexus(T)+wsys
    { [[^You double over and hack up water beneath the pitiless gaze of ([\w'\-]+), your vision distorting and blurring under the force\.$]], { "waterlord" } }, -- nexus(T)
    { [[^You feel suddenly light-headed as ripples race across the amorphous form of ([\w'\-]+)\.$]], { "waterlord" } }, -- nexus(T)+wsys
    { [[^Tendrils of water lash out from the amorphous form of ([\w'\-]+), detaching from \w+ and lashing themselves about you in a freezing embrace.$]], { "waterlord" } }, -- nexus(T)
    { [[^Blood begins to run from your pores as ripples flit across the amorphous form of ([\w'\-]+).$]], { "waterlord" } }, -- nexus(T)
    { [[^Spinning to the \w+ as \w+ draws .+ from its sheath, ([\w'\-]+) delivers a precise slash across your .+\.$]], { "blademaster" } }, -- nexus(T)
    { [[^With a smooth lunge to the \w+, ([\w'\-]+) draws .+ from its scabbard and delivers a powerful slash across your legs\.$]], { "blademaster" } }, -- nexus(T)+wsys
    { [[^In a single motion, ([\w'\-]+) draws .+ from its scabbard and looses a vicious falling slash at your \w+\.$]], { "blademaster" } }, -- nexus(T)
    { [[^As ([\w'\-]+) draws .+ from its scabbard, \w+ drives the pommel into your chin.$]], { "blademaster" } }, -- nexus(T)+wsys
    { [[^Planting \w+ foot between yours, ([\w'\-]+) draws .+ and unleashes a forceful slash that drives you back.$]], { "blademaster" } }, -- nexus(T)+wsys
    { [[^In a single motion, ([\w'\-]+) draws .+ from its scabbard and looses a vicious rising slash at your torso.$]], { "blademaster" } }, -- nexus(T)
    { [[^In a single motion, ([\w'\-]+) draws .+ from its scabbard and looses a vicious falling slash at your head.$]], { "blademaster" } }, -- nexus(T)
    { [[^([\w'\-]+) studies you intently, the howling winds that surround \w+ stilling for a moment.$]], { "airlord" } }, -- levi+nexus(T)+wsys
    { [[^([\w'\-]+) hurls a tarot card with the image of the Hanged Man on it at you. As it reaches you, a huge mass of rope bursts out of it, entrapping and hindering you.$]], { "jester", "occultist" } }, -- nexus(T)
    { [[^With a little laugh, ([\w'\-]+) fashions a piece of wood into the rough semblance of a humanoid.$]], { "jester" } }, -- nexus(T)
    { [[^With an appraising glance at you, ([\w'\-]+) shapes the arms and legs of a rough puppet.$]], { "jester" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) glances at you while adding some facial detail to a puppet.$]], { "jester" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) looks closely at your hands and alters a puppet.$]], { "jester" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) looks at your eyes and makes some alterations to \w+ puppet.$]], { "jester" } }, -- nexus(T)+wsys
    { [[^With one hand ominously pointed towards you, ([\w'\-]+) rubs a finger over the heart of a puppet.$]], { "jester" } }, -- nexus(T)+wsys
    { [[^([\w'\-]+) laughs darkly and squints at you as \w+ adds the final touches to a puppet of you.$]], { "jester" } }, -- nexus(T)
    { [[^([\w'\-]+) gives your head a sound thumping with a blackjack.$]], { "jester" } }, -- nexus(T)
    { [[^([\w'\-]+) reaches out and bops your head with a blackjack.$]], { "jester" } }, -- nexus(T)
    { [[^([\w'\-]+) quickly flings a Hierophant tarot card at you.$]], { "jester", "occultist" } }, -- nexus(T)
    { [[^An ominous feeling descends upon you as ([\w'\-]+) turns \w+ gaze upon you.$]], { "dragon" } }, -- nexus(T)+wsys
    { [[^As the dark intent of ([\w'\-]+) falls upon you, you feel the air surrounding you begin to thrum with tension\.$]], { "airlord" } }, -- levi+wsys
    { [[^([\w'\-]+) clenches a hand into a fist, a sudden force locking closed about your throat and constricting your airflow\.$]], { "airlord" } }, -- levi+wsys
    { [[^([\w'\-]+) casts a hand out in your direction, an icy zephyr descending upon you to tear your fortitude away\.$]], { "airlord" } }, -- levi+wsys
    { [[^A howling wind sweeps over you, its terrible power scouring flesh from bone and leaving your face a bloody ruin by the will of ([\w'\-]+)\.$]], { "airlord" } }, -- levi+wsys
    { [[^([\w'\-]+) quickly pricks you with \w+ dirk\.$]], { "serpent" } }, -- levi+wsys
    { [[^([\w'\-]+) sinks \w+ fangs into you, injecting .+ venom\.$]], { "serpent" } }, -- levi
    { [[^([\w'\-]+) delivers a quick, stinging bite to your body\.$]], { "serpent" } }, -- levi
    { [[^([\w'\-]+) whips \w+ whip at you, ripping away your .+\.$]], { "serpent" } }, -- levi
    { [[^([\w'\-]+) fixes you with an entrancing stare]], { "serpent" } }, -- levi
    { [[^([\w'\-]+) whispers something to a (?:Vodun doll|puppet) of \w+\.$]], { "shaman" } }, -- levi
    { [[^([\w'\-]+) points an imperious finger at you, bringing the curse of \w+ down upon you\.$]], { "shaman" } }, -- levi
    { [[^([\w'\-]+) directs a twin assault of the curses \w+ and \w+ at you\.$]], { "shaman" } }, -- levi
    { [[^([\w'\-]+) laughs sadistically as \w+ jabs an envenomed pin into .+ doll of you\.$]], { "shaman" } }, -- levi
    { [[^([\w'\-]+) points \w+ blood slick daegger at you, slashing a pentagram in the air]], { "apostate" } }, -- levi
    { [[^The whirling daegger of ([\w'\-]+) plunges into your flesh\.$]], { "apostate" } }, -- levi
    { [[^([\w'\-]+) commands \w+ baalzadeen to corrupt your soul\.$]], { "apostate" } }, -- levi
    { [[^Ducking behind you, ([\w'\-]+) strikes at your hamstring]], { "blademaster" } }, -- levi
    { [[^With a smooth lunge to the \w+, ([\w'\-]+) draws]], { "blademaster" } }, -- levi
    { [[^Planting \w+ foot between yours, ([\w'\-]+) draws]], { "blademaster" } }, -- levi
    { [[^([\w'\-]+) spins a full rotation, bringing .+ around in a blur to crash into your]], { "monk" } }, -- levi
    { [[^([\w'\-]+) whips .+ in a controlled arc, bringing the length of the weapon to crash into your]], { "monk" } }, -- levi
    { [[^([\w'\-]+) flows around you like water]], { "monk" } }, -- levi
    { [[^([\w'\-]+) reaches out with \w+ mind, tightening its grip around you]], { "monk" } }, -- levi
    { [[^([\w'\-]+) delivers a powerful uppercut to your]], { "monk" } }, -- levi
    { [[^Dropping into a lower stance, ([\w'\-]+) sweeps .+ at your \w+ thigh\.$]], { "monk" } }, -- levi
    { [[^Snapping back into a ready stance, ([\w'\-]+) whips .+ in a wide arc at your head\.$]], { "monk" } }, -- levi+wsys
    { [[^With pinpoint precision, ([\w'\-]+) thrusts .+ at your throat\.$]], { "monk" } }, -- levi
    { [[^Snapping \w+ leg out to its full extent, ([\w'\-]+) drives a heel into your]], { "monk" } }, -- levi
    { [[^Snapping \w+ arms out in front of \w+, ([\w'\-]+) delivers a lightning-fast thrust]], { "monk" } }, -- levi
    { [[^Spinning on one foot ([\w'\-]+) drives .+ with a lightning-fast thrust\.$]], { "monk" } }, -- levi
    { [[^Continuing \w+ kata, ([\w'\-]+) spins .+ in \w+ hands before driving it in a swift thrust]], { "monk" } }, -- levi
    { [[^Continuing \w+ kata, ([\w'\-]+) drives .+ into your]], { "monk" } }, -- levi
    { [[^With a flourish of .+ ([\w'\-]+) steps in close, \w+ blade slicing at your]], { "bard" } }, -- levi+wsys
    { [[^([\w'\-]+)'s paean slams into you]], { "bard" } }, -- levi
    { [[^([\w'\-]+)'s blade sings with a metallic song]], { "bard" } }, -- levi
    { [[^([\w'\-]+) continues to circle you]], { "bard" } }, -- levi
    { [[^([\w'\-]+) weaves .+ in a complex pattern and]], { "magi" } }, -- levi
    { [[^([\w'\-]+) lifts .+ to point at you and unleashes]], { "magi" } }, -- levi
    { [[^The air thrums about ([\w'\-]+) as \w+ weaves Elemental]], { "magi" } }, -- levi
    { [[^([\w'\-]+) weaves .+ and a torrent of]], { "magi" } }, -- levi
    { [[^([\w'\-]+) forms a lash of fire]], { "magi" } }, -- levi
    { [[^([\w'\-]+) touches a crystal pylon, and a loud vibration rings out]], { "magi" } }, -- levi
    { [[^A crystal pylon vibrates at the command of ([\w'\-]+)]], { "magi" } }, -- levi
    { [[^([\w'\-]+) hurls a bolt of .+ at you]], { "magi" } }, -- levi
    { [[^([\w'\-]+) reaches past you, plunging .+ into your shadow]], { "depthswalker" } }, -- levi+wsys
    { [[^([\w'\-]+) swings .+ scythe at you]], { "depthswalker" } }, -- levi
    { [[^Shadows coalesce around you at the bidding of ([\w'\-]+)]], { "depthswalker" } }, -- levi
    { [[^([\w'\-]+) intones a word of power]], { "depthswalker" } }, -- levi
    { [[^([\w'\-]+) begins dedicating part of \w+ attention to predicting where you shall]], { "depthswalker" } }, -- levi
    { [[^([\w'\-]+) stares at you, eyes smouldering with dark intent\.$]], { "priest" } }, -- levi
    { [[^([\w'\-]+) condemns you to see the fate of the enemies of creation\.$]], { "priest" } }, -- levi
    { [[^([\w'\-]+) directs a dazzling ray of light at you\.$]], { "priest" } }, -- levi
    { [[^([\w'\-]+) commands you to refrain from gluttony\.$]], { "priest" } }, -- levi
    { [[^Raising an imperious hand, ([\w'\-]+) condemns you to suffer the sin of sloth\.$]], { "priest" } }, -- levi
    { [[^([\w'\-]+) carves into your .+ with a vicious strike]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- levi
    { [[^([\w'\-]+) lashes out at you with .+, catching you across the]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- levi
    { [[^([\w'\-]+) invests necromantic energies into]], { "infernal" } }, -- levi
    { [[^([\w'\-]+) draws upon the power of the Hellforge]], { "infernal" } }, -- levi
    { [[^([\w'\-]+) unleashes a bolt of malignant energy at you]], { "infernal" } }, -- levi
    { [[^([\w'\-]+) orders \w+ hyena to attack you]], { "infernal" } }, -- levi
    { [[^([\w'\-]+) excises your corruption]], { "paladin" } }, -- levi
    { [[^([\w'\-]+) calls upon \w+ valour]], { "paladin" } }, -- levi
    { [[^([\w'\-]+) orders \w+ eagle to attack you]], { "paladin" } }, -- levi
    { [[^As fire surges about the righteous ([\w'\-]+)]], { "paladin" } }, -- levi
    { [[^([\w'\-]+) looms over you, all righteous wrath]], { "paladin" } }, -- levi
    { [[^([\w'\-]+) sketches a rune upon you]], { "runewarden" } }, -- levi
    { [[^([\w'\-]+) touches a rune on the ground and it flares]], { "runewarden" } }, -- levi
    { [[^([\w'\-]+) orders \w+ falcon to attack you]], { "runewarden" } }, -- levi
    { [[^Cold blue flames wreathe ([\w'\-]+)'s runeblade]], { "runewarden" } }, -- levi
    { [[^([\w'\-]+) croons a discordant note at you]], { "unnamable" } }, -- levi
    { [[^([\w'\-]+) channels the power of anathema]], { "unnamable" } }, -- levi
    { [[^([\w'\-]+) orders \w+ chimera to attack you]], { "unnamable" } }, -- levi
    { [[^([\w'\-]+) throws back \w+ head and utters a string of words]], { "occultist" } }, -- levi
    { [[^([\w'\-]+) passes \w+ hand in front of you]], { "occultist" } }, -- levi
    { [[^([\w'\-]+) flings a .+ tarot card at you]], { "occultist", "jester" } }, -- levi
    { [[^([\w'\-]+) whispers something to a puppet of you]], { "jester" } }, -- levi
    { [[^([\w'\-]+) throws a pie at you]], { "jester" } }, -- levi
    { [[^([\w'\-]+) jabs an envenomed needle into a puppet of you]], { "jester" } }, -- levi
    { [[^([\w'\-]+) glowers at you with a look of repressed disgust]], { "alchemist" } }, -- levi
    { [[^A diminutive homunculus resembling ([\w'\-]+) stares menacingly at you]], { "alchemist" } }, -- levi
    { [[^A translucent lash coalesces in ([\w'\-]+)'s hands]], { "psion" } }, -- levi
    { [[^([\w'\-]+) delivers a series of lashes against you]], { "psion" } }, -- levi
    { [[^Golden chains of light coalesce in the hands of ([\w'\-]+)]], { "psion" } }, -- levi
    { [[^([\w'\-]+) unleashes a swarm of pestilent insects upon you]], { "pariah" } }, -- levi
    { [[^([\w'\-]+) calls upon the power of memorium]], { "pariah" } }, -- levi
    { [[^([\w'\-]+) drives .+ charnel weapon into your]], { "pariah" } }, -- levi
    { [[^([\w'\-]+) sweeps .+ knife in a circle above \w+ head]], { "pariah" } }, -- levi
    { [[^([\w'\-]+) traces a logograph depicting]], { "pariah" } }, -- levi
    { [[^([\w'\-]+) raises \w+ right hand, and snaps \w+ fingers]], { "pariah" } }, -- levi+wsys
    { [[^([\w'\-]+) rakes you with .+ claws]], { "druid" } }, -- levi
    { [[^([\w'\-]+)'s hydra head lunges at you]], { "druid" } }, -- levi
    { [[^([\w'\-]+) lashes at you with .+ tail]], { "druid" } }, -- levi
    { [[^([\w'\-]+) reclaims the land around you]], { "druid" } }, -- levi
    { [[^([\w'\-]+) hurls .+ axe at you]], { "sentinel" } }, -- levi
    { [[^([\w'\-]+) commands \w+ (?:spider|wolf|hawk|bear) to attack you]], { "sentinel" } }, -- levi
    { [[^([\w'\-]+) strikes you with a quick skirmishing blow]], { "sentinel" } }, -- levi
    { [[^([\w'\-]+) lays open your flesh with an expert lateral slice]], { "sentinel" } }, -- levi
    { [[^Turning with the motion of \w+ strike, ([\w'\-]+) comes back around to slam]], { "sentinel" } }, -- levi
    { [[^([\w'\-]+) swiftly sweeps your feet out from beneath you with]], { "sentinel" } }, -- levi
    { [[^([\w'\-]+) savagely gouges into you with]], { "sentinel" } }, -- levi+wsys
    { [[^Agony radiates out from the point of impact as ([\w'\-]+) brings the haft of]], { "sentinel" } }, -- levi
    { [[^([\w'\-]+) thrusts \w+ blade angrily towards you, but you dodge]], { "sentinel" } }, -- levi
    { [[^([\w'\-]+) gestures and thorny vines erupt from the ground]], { "sylvan" } }, -- levi
    { [[^([\w'\-]+) calls upon the power of the weather]], { "sylvan" } }, -- levi
    { [[^([\w'\-]+) propagates the growth around you]], { "sylvan" } }, -- levi
    { [[^([\w'\-]+) mauls you viciously with .+ claws]], { "dragon" } }, -- levi
    { [[^([\w'\-]+) breathes a stream of (?:fire|frost|lightning|acid) at you]], { "dragon" } }, -- levi
    { [[^([\w'\-]+) lashes out at you with .+ tail]], { "dragon" } }, -- levi
    { [[^([\w'\-]+) slams the ground and a pillar of stone erupts beneath you]], { "earthlord" } }, -- levi
    { [[^([\w'\-]+) causes the earth to tremble violently beneath you]], { "earthlord" } }, -- levi
    { [[^([\w'\-]+) commands the earth to swallow you]], { "earthlord" } }, -- levi
    { [[^([\w'\-]+) hurls a ball of fire at you]], { "firelord" } }, -- levi
    { [[^([\w'\-]+) summons a pillar of flame beneath you]], { "firelord" } }, -- levi
    { [[^([\w'\-]+) engulfs you in a torrent of fire]], { "firelord" } }, -- levi
    { [[^([\w'\-]+) sends a torrent of water crashing into you]], { "waterlord" } }, -- levi
    { [[^([\w'\-]+) conjures a wave of water to engulf you]], { "waterlord" } }, -- levi
    { [[^([\w'\-]+) freezes the water around you]], { "waterlord" } }, -- levi
    { [[^([\w'\-]+) brings .+ down upon you with a brutal overhand blow\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- levi+wsys
    { [[^([\w'\-]+) explodes upward from a low crouch, driving .+ toward your]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- levi+wsys
    { [[^([\w'\-]+) comes around with a terrible swing of .+ toward your]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- levi
    { [[^([\w'\-]+) quickly lunges to the side, bringing \w+ shield around to smash into]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- levi
    { [[^([\w'\-]+) drives the edge of \w+ shield .+ into your throat]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- levi
    { [[^([\w'\-]+) smashes the edge of .+ into your kneecaps]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- levi
    { [[^([\w'\-]+) pivots rapidly and brings \w+ shield around to batter your head]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- levi
    { [[^([\w'\-]+) summons up a gale, sending it towards you\.$]], { "airlord" } }, -- wsys
    { [[^The etheric light around you abruptly fades, and you feel a sudden release of tension as the hissing noise ceases entirely\. Through a rapidly closing fold in the ether, you catch a glimpse of the face of ([\w'\-]+)\.$]], { "alchemist" } }, -- wsys
    { [[^([\w'\-]+) illuminates you with a radiant light\.$]], { "alchemist" } }, -- wsys
    { [[^([\w'\-]+) waves a hand in your direction and you feel energy wreathing about you\. A strong burning sensation rushes through your body\.$]], { "alchemist" } }, -- wsys
    { [[^A short convulsion sweeps through your body as ([\w'\-]+) wracks your \w+ humour\.$]], { "alchemist" } }, -- wsys
    { [[^A short convulsion sweeps through your body as ([\w'\-]+) wracks your \w+ and \w+ humours\.$]], { "alchemist" } }, -- wsys
    { [[^A diminutive homunculus resembling ([\w'\-]+) turns its head towards you, its jaws opening wider than what seems possible\. The homunculus stares intently at you and lets out an ear-piercing shriek that disrupts your thoughts\.$]], { "alchemist" } }, -- wsys
    { [[^A diminutive homunculus resembling ([\w'\-]+) stares intendedly at you, its eyes flashing a deep blue\. A strange feeling spreads through your body as your melancholic and sanguine humours become corrupted\.$]], { "alchemist" } }, -- wsys
    { [[^A sudden nausea and lightheadedness takes hold of your body, and you struggle to hold on to consciousness under ([\w'\-]+)'s assault\.$]], { "alchemist" } }, -- wsys
    { [[^A diminutive homunculus resembling ([\w'\-]+) claws into your flesh with dirty nails. The surrounding flesh begins to swell with fluid\.$]], { "alchemist" } }, -- wsys
    { [[^([\w'\-]+) waves a hand in your direction and you feel energy wreathing about you\. Small patches of your skin waver before turning into shards of sharp glass\.$]], { "alchemist" } }, -- wsys
    { [[^\w+ eyes closing momentarily, ([\w'\-]+) sinks into deep concentration. When \w+ opens \w+ eyes once more, a diminutive homunculus resembling \w+ stands ready at \w+ side\.$]], { "alchemist" } }, -- wsys
    { [[^With a snarl, ([\w'\-]+)'s Baalzadeen opens its mouth and spews a foul black liquid all over you\.$]], { "apostate" } }, -- wsys
    { [[^([\w'\-]+)'s Baalzadeen casts a piercing glance at you\.$]], { "apostate" } }, -- wsys
    { [[^Before you can avoid it, ([\w'\-]+)'s hand brushes against your arm and it withers away\.$]], { "apostate" } }, -- wsys
    { [[^You watch in horror as ([\w'\-]+) touches your \w+ arm, and it shrivels away to uselessness\.$]], { "apostate", "occultist" } }, -- wsys
    { [[^You stumble slightly as ([\w'\-]+) touches your \w+ leg, and it shrivels away\.$]], { "apostate", "occultist" } }, -- wsys
    { [[^([\w'\-]+) reaches out and grabs your leg, which almost gives way underneath you as it shrivels feebly away\.$]], { "apostate" } }, -- wsys
    { [[^([\w'\-]+)'s flashing blade dances before your eyes in a series of complicated feints\. Time to run!$]], { "bard" } }, -- wsys
    { [[^A bell-like tone rings out from ([\w'\-]+)'s \w+\, echoed by the sound of cracking bone as your (?:left|right) (?:arm|leg) snaps painfully\.$]], { "bard" } }, -- wsys
    { [[^([\w'\-]+) lightly strikes the side of your head with \w+ \w+\, restoring your hearing\.$]], { "bard" } }, -- wsys
    { [[^You're knocked to the ground by the impact of ([\w'\-]+)'s feet\. Your surprise is quickly supplanted by pain as \w+ skewers you like a wild boar\.$]], { "bard" } }, -- wsys
    { [[^With a deadly grace ([\w'\-]+) begins to circle you, rapier poised and ready to strike\.$]], { "bard" } }, -- wsys
    { [[^([\w'\-]+) flicks out with .+ towards you, a keening note raising from the blade's lunge\.$]], { "bard" } }, -- wsys
    { [[^A rich, vibrant hum rises from the blade of ([\w'\-]+) as it finds your flesh\.$]], { "bard" } }, -- wsys
    { [[^The staccato song of .+ punctuates a flurry of blows as ([\w'\-]+)'s blade pursues you relentlessly\.$]], { "bard" } }, -- wsys
    { [[^([\w'\-]+) strikes only air with .+ flurry of blows, the tip of .+ rapier flickering before your face\.$]], { "bard" } }, -- wsys
    { [[^([\w'\-]+)'s blade sings with a metallic song as .+ directs a deep cut towards your .+\.$]], { "bard" } }, -- wsys
    { [[^.+ eyes gleaming, ([\w'\-]+) smiles and quickly sings a jaunty limerick at you\.$]], { "bard" } }, -- wsys
    { [[^Moving with unpredictable grace, ([\w'\-]+) sends a dancing blow towards you\.$]], { "blademaster" } }, -- wsys
    { [[^Whispering a prayer to the \w+ winds, ([\w'\-]+) draws \w+ \w+ and unleashes a slash towards your .+\.$]], { "blademaster" } }, -- wsys
    { [[^In a single motion, ([\w'\-]+) draws \w+ \w+ from its scabbard and looses a vicious rising slash at your .+\.$]], { "blademaster" } }, -- wsys
    { [[^([\w'\-]+) darts to your mount's flank in a rapid dash\. Grabbing your ankle and executing a graceful twist, \w+ sends you tumbling from the saddle\.$]], { "blademaster" } }, -- wsys
    { [[^Fists clenched, ([\w'\-]+) focuses on you with a deadly look in \w+ eyes\.$]], { "blademaster" } }, -- wsys
    { [[^Spinning to the \w+ as \w+ draws \w+ \w+ from its sheath, ([\w'\-]+) delivers a precise slash across your arms\.$]], { "blademaster" } }, -- wsys
    { [[^([\w'\-]+) unleashes a vicious slash towards you before resheathing (?:his|her|faes) blade, \w+ \w+\.$]], { "blademaster" } }, -- wsys
    { [[^With fluid motions of \w+ iron fingers, ([\w'\-]+) strikes precisely at your neck\.$]], { "blademaster" } }, -- wsys
    { [[^Sweeping out with a blade hand, ([\w'\-]+) strikes at the back of your knee\.$]], { "blademaster" } }, -- wsys
    { [[^With rapid precision, ([\w'\-]+) aims first a punch then a spearhand blow at two points on your chest\.$]], { "blademaster" } }, -- wsys
    { [[^With a fluid motion, ([\w'\-]+) aims a blow just below your shoulder\.$]], { "blademaster" } }, -- wsys
    { [[^Lashing out with open palms, ([\w'\-]+) boxes your ears\.$]], { "blademaster" } }, -- wsys
    { [[^Ducking behind you, ([\w'\-]+) strikes at your hamstring with a rigid grip\.$]], { "blademaster" } }, -- wsys
    { [[^With iron fingers, ([\w'\-]+) aims a darting strike at your throat\.$]], { "blademaster" } }, -- wsys
    { [[^The muscles of your stomach clench as ([\w'\-]+) strikes you with a measured blow\.$]], { "blademaster" } }, -- wsys
    { [[^With pinpoint strikes to your eye sockets, ([\w'\-]+) causes your sight to waver and blur\.$]], { "blademaster" } }, -- wsys
    { [[^([\w'\-]+) lays into you with a savage blow from (?:.+)\.$]], { "depthswalker" } }, -- wsys
    { [[^([\w'\-]+) raises (?:.+) and points it at you with a sinister smile\.$]], { "depthswalker" } }, -- wsys
    { [[^As the gaze of ([\w'\-]+) falls upon you, you feel your speed enhancements torn away.$]], { "depthswalker" } }, -- wsys
    { [[^([\w'\-]+) slashes a hand in your direction and you feel yourself suddenly slow down to a terrifying degree.$]], { "depthswalker" } }, -- wsys
    { [[^A grey distortion coalesces about the blade of .+, held by ([\w'\-]+).$]], { "depthswalker" }, acted = false }, -- wsys
    { [[^([\w'\-]+) lunges forward with long\, flashing (?:[\w'\-]+) extended\, tearing down to the bones of your (?:right leg|left leg|right arm|left arm|head|torso)\.$]], { "dragon" } }, -- wsys
    { [[^([\w'\-]+) snaps (?:\w+) massive jaws close around you, flinging you effortlessly into the air before catching you with a second powerful bite\.$]], { "dragon" } }, -- wsys
    { [[^([\w'\-]+) turns to fix [\w'\-]+ gaze upon you\, and you feel your heart increase its palpitations as a low keening echoes from [\w'\-]+ throat\.$]], { "dragon" } }, -- wsys
    { [[^You are knocked forcefully off your feet by the impact of ([\w'\-]+)'s huge tail\.$]], { "dragon" } }, -- wsys
    { [[^Lunging forward with long, flashing claws extended, ([\w'\-]+) tears into you ruthlessly\.$]], { "dragon" } }, -- wsys
    { [[^Drawing an enormous breath, ([\w'\-]+) exhales, expelling a gale of wind with such force that you are knocked over\.$]], { "dragon" } }, -- wsys
    { [[^Your body trembles as ([\w'\-]+) invokes a dramatic chant in the dragon tongue. As (?:his|her|faes) voice resonates, you are assailed by a wave of magical energy that threatens to tear your skin apart\.$]], { "dragon" } }, -- wsys
    { [[^A heavy burden descends upon your soul as ([\w'\-]+) lays the ancient Dragoncurse upon you\.$]], { "dragon" } }, -- wsys
    { [[^([\w'\-]+) fixes [\w'\-]+ gaze upon [\w'\-]+\, swaying slowly as [\w'\-]+ begins a low keening\.$]], { "dragon" } }, -- wsys
    { [[^([\w'\-]+) snaps [\w'\-]+ massive jaws close around you\, jerking you back and forth with agonising strength\.$]], { "dragon" } }, -- wsys
    { [[^A deathly calm descends upon your surroundings as ([\w'\-]+) draws \w+ up regally\, eyes gleaming with murderous intent\.$]], { "dragon" } }, -- wsys
    { [[^([\w'\-]+) rises back on [\w'\-]+ hind legs\, more than doubling in height as [\w'\-]+ towers above you\. The ground shakes violently as [\w'\-]+ slams [\w'\-]+ feet back down\, recklessly crushing everyone in [\w'\-]+ path\.$]], { "dragon" } }, -- wsys
    { [[^([\w'\-]+) flicks [\w'\-]+ tail at you\, effortlessly shattering your magical shield\.$]], { "dragon" } }, -- wsys
    { [[^([\w'\-]+)'s powerful chest expands as [\w'\-]+ takes a mighty breath\, loosing a shrill volley of [\w'\-]+\-infused vapour into the air\.$]], { "dragon" }, acted = false }, -- wsys
    { [[^([\w'\-]+)\'s tail narrowly misses you as it whips in a circle\.$]], { "dragon" }, acted = false }, -- wsys
    { [[^The fire on the hands of ([\w'\-]+) jumps to you, setting you ablaze\.$]], { "druid" } }, -- wsys
    { [[^Quicker than you can follow, one of ([\w'\-]+)'s serpentine heads darts forward to snap at your flesh\.$]], { "druid" } }, -- wsys
    { [[^With \w+ deadly tail, ([\w'\-]+) strikes out at you and stings you\.$]], { "druid" } }, -- wsys
    { [[^A mighty, bestial roar from ([\w'\-]+) sends you from your feet with its sheer force\.$]], { "druid" } }, -- wsys
    { [[^As ([\w'\-]+) strikes you, you stumble back from the searing heat, tripping to the ground\.$]], { "druid" } }, -- wsys
    { [[^([\w'\-]+) rains a flurry of blows down upon you with (?:\w+) great stone fists\.$]], { "earthlord" } }, -- wsys
    { [[^([\w'\-]+) swings a magma-wreathed fist at you, but you duck aside at the last moment\.$]], { "earthlord" } }, -- wsys
    { [[^([\w'\-]+) brings a magma-wreathed fist around impossibly fast, driving it clean through your magical shield in an explosion of translucent shards\.$]], { "earthlord" } }, -- wsys
    { [[^([\w'\-]+) slams a foot to the ground, great tremors radiating out from the impact\.$]], { "earthlord" } }, -- wsys
    { [[^The stone fist of ([\w'\-]+) crunches into your .*\.$]], { "earthlord" } }, -- wsys
    { [[^You feel bones grinding against one another as the fist of ([\w'\-]+) smashes into your .* with pulverising force\.$]], { "earthlord" } }, -- wsys
    { [[^The magma\-wreathed form of ([\w'\-]+) smashes into you\, crushing you beneath [\w'\-]+ massive bulk and searing you to the bone\.$]], { "earthlord" } }, -- wsys
    { [[^Magma ceases to bubble up from beneath the outer strata of ([\w'\-]+)\.$]], { "earthlord" }, acted = false }, -- wsys
    { [[^The rock plates covering the form of ([\w'\-]+) rapidly thicken\, sharp spires of stone rapidly sprouting from them\.$]], { "earthlord" }, acted = false }, -- wsys
    { [[^Cloaked in a shifting mantle of molten stone, ([\w'\-]+) charges in from the (?:\w+) with a deafening roar\.$]], { "earthlord" }, acted = false }, -- wsys
    { [[^Magma erupts from the cracks between the plates covering ([\w'\-]+)\, cloaking [\w'\-]+ in a churning shroud of molten stone\.$]], { "earthlord" }, acted = false }, -- wsys
    { [[^The flames that are the eyes of ([\w'\-]+) flare as (?:\w+) rakes them across you in an imperious glare\.$]], { "firelord" } }, -- wsys
    { [[^([\w'\-]+) flicks a finger in your direction, a single brilliant tongue of flame leaping from \w+ to you\.$]], { "firelord" } }, -- wsys
    { [[^A fiery comet streaks into the location, resolving into the incandescent form of ([\w'\-]+)\. \w+ smashes into you, a fiery detonation radiating outwards\.$]], { "firelord" } }, -- wsys
    { [[^A crown of burning white fire comes into being about the head of ([\w'\-]+), its tendrils reaching out to consume\.$]], { "firelord" } }, -- wsys
    { [[^([\w'\-]+) raises a flame-wreathed hand to point at the brand that burns relentlessly upon your brow\.$]], { "firelord" } }, -- wsys
    { [[^The flames that compose ([\w'\-]+) flare ever brighter\.$]], { "firelord" }, acted = false }, -- wsys
    { [[^The searing white flames that compose ([\w'\-]+) fade to orange\.$]], { "firelord" }, acted = false }, -- wsys
    { [[^The flames that are ([\w'\-]+) turn from blue to an eye-searing white\.$]], { "firelord" }, acted = false }, -- wsys
    { [[^The warping of the air surrounding ([\w'\-]+) calms, as \w+ ceases to burn with such intensity\.$]], { "firelord" }, acted = false }, -- wsys
    { [[^The burning crown upon the head of ([\w'\-]+) flickers out of existence\.$]], { "firelord" }, acted = false }, -- wsys
    { [[^Throwing \w+ arms wide, ([\w'\-]+) calls up a raging inferno to consume the location\.$]], { "firelord" }, acted = false }, -- wsys
    { [[^Spreading \w+ arms wide, ([\w'\-]+) decrees that this location shall serve as a crucible for the glory of Kkractle.\$]], { "firelord" }, acted = false }, -- wsys
    { [[^The loud crackling of the flames composing ([\w'\-]+) grows quiet\.$]], { "firelord" }, acted = false }, -- wsys
    { [[^The ominous crackling of the flames that are ([\w'\-]+) grow ever louder\.$]], { "firelord" }, acted = false }, -- wsys
    { [[^The fiery outer layers of ([\w'\-]+) fall away, turning to dust as they drift to the ground\. Though (?:\w+) seems diminished for an instant, \w+ fires soon rage with fury once more\.$]], { "firelord" }, acted = false }, -- wsys
    { [[^A crimson shroud of flame bursts into being around ([\w'\-]+), completely cloaking \w+ in a rippling cloak of fire\.$]], { "firelord" }, acted = false }, -- wsys
    { [[^([\w'\-]+) flicks a finger in the direction of a large wall of ice, and it instantly explodes into scalding steam\.$]], { "firelord" }, acted = false }, -- wsys
    { [[^A column of flame bursts up from the earth from which emerges the incandescent form of ([\w'\-]+)\. Flames leap out from \w+, searing you\.$]], { "firelord" }, acted = false }, -- wsys
    { [[^([\w'\-]+) wreathes (?:his|her|faes) hand in black lightning, delivering a savage backhand to your face that sends the profane energy ripping through your body\.$]], { "infernal" } }, -- wsys
    { [[^Pain becomes a familiar foe as ([\w'\-]+) reaches out and grasps you by your (?:left|right) (?:arm|leg) and (?:left|right) (?:arm|leg), violently hoisting you into the air before cruelly twisting and wrenching at your fragile bones\.$]], { "infernal" } }, -- wsys
    { [[^([\w'\-]+) reaches out and bops you on the nose with (?:his|her|faes) blackjack\.$]], { "jester" } }, -- wsys
    { [[^([\w'\-]+) sets a jack\-in\-the\-box on the ground and quickly winds it while whispering, '(?:\w+)\.' The cheerful music of a lute begins to emanate from it\.$]], { "jester" } }, -- wsys
    { [[^A wave of heat rolls over you from the direction of ([\w'\-]+), and flames ignite upon your skin\.$]], { "magi" } }, -- wsys
    { [[^([\w'\-]+) makes the slightest flick with an elemental staff, and a deluge of freezing water descends like the hand of some angered titan to smash you with a hammer colder than the oldest grave\.$]], { "magi" } }, -- wsys
    { [[^([\w'\-]+) points an elemental staff at you, and an intangible wave of something strikes forth to smite you\. Your bones convulse within your body, and a terrible sense of wrongness sweeps throughout your mortal shell\.$]], { "magi" } }, -- wsys
    { [[^([\w'\-]+) forms a lash of fire, and sends it to painfully scorch your flesh\.$]], { "magi" } }, -- wsys
    { [[^([\w'\-]+) calls upon \w+ and unleashes a forceful blow at you(?:r (?:left arm|right arm|left leg|right leg|torso|head))? with (?:his|her|faes) staff\.$]], { "magi" } }, -- wsys
    { [[^([\w'\-]+) dodges nimbly to the side and trips you to the floor\.$]], { "monk" } }, -- wsys
    { [[^([\w'\-]+) knocks your legs out from under you and sends you sprawling to the floor\.$]], { "monk" } }, -- wsys
    { [[^([\w'\-]+) moves in and delivers a precision strike to your neck as you attack\.$]], { "monk" } }, -- wsys
    { [[^([\w'\-]+) violently grabs your already damaged \w+ \w+, wrenches you off balance, then throws you violently to the ground\.$]], { "monk" } }, -- wsys
    { [[^([\w'\-]+) slams into you, knocking you off your feet and stunning you!$]], { "monk" } }, -- wsys
    { [[^([\w'\-]+) twists (?:his|her|faes) torso and sends a roundhouse towards you\.$]], { "monk" } }, -- wsys
    { [[^([\w'\-]+) whips .+ in a controlled arc, bringing the length of the weapon to crash into your (?:left|right) arm\.$]], { "monk" } }, -- wsys
    { [[^([\w'\-]+) whips .+ in a long sweep at your legs\.$]], { "monk" } }, -- wsys
    { [[^Snapping \w+ arms out in front of him, ([\w'\-]+) delivers a lightning-fast thrust with .+ to your (?:left|right) arm\.$]], { "monk" } }, -- wsys
    { [[^Bracing \w+ back foot, ([\w'\-]+) lunges forward with .+ at your face\.$]], { "monk" } }, -- wsys
    { [[^Reversing \w+ grip on .+, ([\w'\-]+) drives the top of the weapon into your throat\.$]], { "monk" } }, -- wsys
    { [[^Whirling around, ([\w'\-]+) drives the ball of \w+ foot into your ribs\.$]], { "monk" } }, -- wsys
    { [[^([\w'\-]+) flows around you like water, .+ lashing out in a swift thrust at your vulnerable kidneys\.$]], { "monk" } }, -- wsys
    { [[^Stepping forward, ([\w'\-]+) drives .+ at your face\.$]], { "monk" } }, -- wsys
    { [[^You feel ([\w'\-]+)'s mind attacking yours from all sides, and you lose your mental equilibrium\.$]], { "monk" } }, -- wsys
    { [[^You reel as your mind is viciously battered by a mental assault from ([\w'\-]+)\.$]], { "monk" } }, -- wsys
    { [[^Blue light crackles forth from ([\w'\-]+)'s palms, striking you down and snapping your puny limbs\.$]], { "monk" } }, -- wsys
    { [[^A shimmering image of the face of ([\w'\-]+) appears fleetingly before you, frowning in concentration\.$]], { "monk" } }, -- wsys
    { [[^You feel your body and mind ripped apart as you are enfeebled by ([\w'\-]+)\.$]], { "monk" } }, -- wsys
    { [[^([\w'\-]+) draws back with a knowing smirk and utters some alien word that vibrates deep within your bones\. Your mind swirls and body convulses in excruciating pain as your very spirit cries out in agony\.$]], { "occultist" } }, -- wsys
    { [[^([\w'\-]+) lowers (?:\w+) eyes and an unearthly image appears before you\. Unable to accept what this vision means, your thoughts become jumbled\.$]], { "occultist" } }, -- wsys
    { [[^([\w'\-]+) speaks something in an unknown and impossible language\. Unable to process the alien images these words induce, your thoughts become jumbled\.$]], { "occultist" } }, -- wsys
    { [[^([\w'\-]+) utters a terrible curse and points a finger at you\.$]], { "occultist" } }, -- wsys
    { [[^([\w'\-]+) gestures sharply in your direction, and a mass of green slime flows up and over you, coating your skin\.$]], { "occultist" } }, -- wsys
    { [[^Seven rays of different coloured light spring out from ([\w'\-]+)'s outstretched hands, irradiating the location with blinding strobes\.$]], { "occultist" } }, -- wsys
    { [[^([\w'\-]+) sends an icy blue tendril of light that lashes out at you and wraps around you, sending a strange chill deep into your bones\.$]], { "occultist" } }, -- wsys
    { [[^([\w'\-]+) makes a sharp motion with one hand in your direction, the briefest flicker of something crackling between (?:\w+) digits\.$]], { "occultist" } }, -- wsys
    { [[^Before you can avoid it, ([\w'\-]+) hand brushes against your (?:\w+) and it withers away\.$]], { "occultist" } }, -- wsys
    { [[^([\w'\-]+) makes a sudden, quick gesture in front of you, almost hitting your nose\. (?:\w+) hand glows with a vibrant violet light before snapping back to (?:\w+) side\.$]], { "occultist" } }, -- wsys
    { [[^A nimbus of flame blazes about ([\w'\-]+) as (?:\w+) turns (?:\w+) righteousness upon you.$]], { "paladin" } }, -- wsys
    { [[^.+ flares with brilliant flame as ([\w'\-]+) lunges for you!$]], { "paladin" } }, -- wsys
    { [[^Fire burns in the eyes of ([\w'\-]+) as (?:\w+) turns (?:\w+) righteous attention towards you.$]], { "paladin" } }, -- wsys
    { [[^([\w'\-]+) whispers a prayer to the Righteous Fire, and white flame bursts into Creation to scour your blight away\.$]], { "paladin" } }, -- wsys
    { [[^At the command of ([\w'\-]+) a beam of radiance strikes down from on high, transfixing you with its relentless glare.$]], { "paladin" } }, -- wsys
    { [[^([\w'\-]+) is outlined in a nimbus of fire for an instant as (?:\w+) glares at you, but it abruptly winks out\.$]], { "paladin" } }, -- wsys
    { [[^As fire surges about the righteous ([\w'\-]+), a terrible heat fills your chest, a scorching pain that threatens to scour you from Creation\.$]], { "paladin" } }, -- wsys
    { [[^([\w'\-]+) sweeps (?:.+) in a circle above (?:\w+) head, the point of the blade coming to rest aimed at you\. You feel a sharp pain, gone as swiftly as it came, and a fine crimson spray falls about you and (?:\w+)\.$]], { "pariah" } }, -- wsys
    { [[^([\w'\-]+) raises (?:\w+) left hand in front of you, clenching it into a fist, your body spasming under some arcane assault\.$]], { "pariah" } }, -- wsys
    { [[^([\w'\-]+) traces a writhing logograph in the air before you, the blood upon \w+ knife bursting into arcane flame as it hangs in the wake of the blade's passage\.$]], { "pariah" } }, -- wsys
    { [[^([\w'\-]+) traces a logograph (?:.+) in the air before you, the blood upon .+ knife bursting into arcane flame as it hangs in the wake of the blade's passage\.$]], { "pariah" } }, -- wsys
    { [[^([\w'\-]+) raises \w+ right hand, a spark of something leaping between \w+ fingers as \w+ snaps them\.$]], { "pariah" }, acted = false }, -- wsys
    { [[^([\w'\-]+) withdraws a small stone jar from a pouch at \w+ waist, tipping a few drops of the contents onto (?:.+)\.$]], { "pariah" }, acted = false }, -- wsys
    { [[^([\w'\-]+) carefully unscrews the lid of a small stone jar, tapping (?:.+) against the open mouth and letting the life's blood upon the blade drip inside\.$]], { "pariah" }, acted = false }, -- wsys
    { [[^([\w'\-]+)'s hand lashes out, (?:\w+) glittering ritual blade flashing as drops of crimson blood land upon its ensorceled blade\.$]], { "pariah" }, acted = false }, -- wsys
    { [[^"Know the pain which you have caused," ([\w'\-]+) proselytises, finger pointed directly at you\.$]], { "priest" } }, -- wsys
    { [[^([\w'\-]+) strikes you with a dark bolt of energy directed through \w+ mace\.$]], { "priest" } }, -- wsys
    { [[^"Repent for your crimes\!" ([\w'\-]+) denounces you, hand raised in warding\.$]], { "priest" } }, -- wsys
    { [[^([\w'\-]+)'s guardian angel's eyes glow like embers as searing heat pours over you, causing you to burst into flames\.$]], { "priest" } }, -- wsys
    { [[^Your .+ defence has been stripped by ([\w'\-]+)'s guardian angel\.$]], { "priest" } }, -- wsys
    { [[^([\w'\-]+) draws you into (?:\w+) gaze, lowering (?:\w+) brow and glaring at you with righteous fury\. Pointing at you with a single raised finger, (?:\w+) recites a list of your transgressions, condemning your actions and words\. A blaze of holy fire surges about (?:\w+) as (?:\w+) dictates your sentence\.$]], { "priest" } }, -- wsys
    { [[^Your \w+ arm flops uselessly as ([\w'\-]+) severs the muscles in it with a precise blow of (?:\w+) translucent sword\.$]], { "psion" } }, -- wsys
    { [[^With a brutal thrust of a translucent sword, ([\w'\-]+) sinks \w+ weapon into your guts, ripping it free in a spray of crimson\.$]], { "psion" } }, -- wsys
    { [[^([\w'\-]+) gives a great shout of exertion as (?:\w+) eyes lock with yours, and a terrible pain explodes within your skull, your vision blacking out and your skull feeling like it shall burst apart at any moment\.$]], { "psion" } }, -- wsys
    { [[^A terrible weariness overcomes you as ([\w'\-]+) darts out (?:\w+) blade and drives the tip into you just beneath your right shoulder\.$]], { "psion" } }, -- wsys
    { [[^Golden chains of light coalesce in the hands of ([\w'\-]+), and (?:he|she|fae) casts them out to bind you to \w+\.$]], { "psion" } }, -- wsys
    { [[^In a blur of motion ([\w'\-]+) rushes at you, \w+ blade rending your flesh in a devastating flurry of \d+ strokes\.$]], { "psion" } }, -- wsys
    { [[^([\w'\-]+) delivers a series of lashes against you with a translucent lash, and the very fabric of your being violently rebels against your mortal flesh\.$]], { "psion" } }, -- wsys
    { [[^([\w'\-]+) ducks low, (?:\w+) blade slicing into your (?:.+)\.$]], { "psion" } }, -- wsys
    { [[^A translucent sword coalesces in ([\w'\-]+)'s hands, firming as it gains substance beyond the incorporeal\.$]], { "psion" }, acted = false }, -- wsys
    { [[^Cold blue flames wreathe ([\w'\-]+)'s runeblade, emanating an icy chill that penetrates you to the bone\.$]], { "runewarden" } }, -- wsys
    { [[^As you turn away from ([\w'\-]+), (?:he|she|fae) delivers a vicious blow to your back, a jolt of power throwing you off balance\.$]], { "runewarden" } }, -- wsys
    { [[^The runic configuration upon .+ in the grasp of ([\w'\-]+) flashes bright\!$]], { "runewarden" }, acted = false }, -- wsys
    { [[^With a pointed stick, ([\w'\-]+) begins sketching a rune on the ground.$]], { "runewarden" }, acted = false }, -- wsys
    { [[^The kena rune flashes bright upon a .+ in the hand of ([\w'\-]+).$]], { "runewarden" }, acted = false }, -- wsys
    { [[^([\w'\-]+) deftly thrusts .+? into you]], { "sentinel" } }, -- wsys
    { [[^([\w'\-]+) thrusts .+? towards you\.$]], { "sentinel" } }, -- wsys
    { [[^([\w'\-]+) takes a step forward, bringing .+? in for a second quick jab\.$]], { "sentinel" } }, -- wsys
    { [[^([\w'\-]+) flourishes .+? in front of your eyes, mesmerising you\.$]], { "sentinel" } }, -- wsys
    { [[^([\w'\-]+) expertly flourishes .+? in front of your face\.$]], { "sentinel" } }, -- wsys
    { [[^Your world becomes nothing but stars as the haft of .+? slams into the side of your head, courtesy of ([\w'\-]+)\.$]], { "sentinel" } }, -- wsys
    { [[^([\w'\-]+) quickly trusses you up\.$]], { "sentinel" } }, -- wsys
    { [[^Agony radiates out from the point of impact as ([\w'\-]+) brings the haft of .+? down upon your head with crushing force\.$]], { "sentinel" } }, -- wsys
    { [[^([\w'\-]+) locks (?:his|her|faes) unnatural gaze to yours, and a terrible pressure begins to build behind your eyes\.$]], { "sentinel" } }, -- wsys
    { [[^([\w'\-]+) lays open your flesh with an expert lateral slice with .+?\.$]], { "sentinel" } }, -- wsys
    { [[^Terrible pain radiates from the weapon impaling you as ([\w'\-]+) gives it a violent twist\.$]], { "sentinel" } }, -- wsys
    { [[^([\w'\-]+) deftly hooks (?:.+) behind your foot and sends you tumbling off (?:.+) before driving the point of the weapon into your (?:right|left) leg\.$]], { "sentinel" } }, -- wsys
    { [[^([\w'\-]+) whips (?:.+) in a swift motion toward you, scything through your (?:.+) defence\.$]], { "sentinel" } }, -- wsys
    { [[^([\w'\-]+) swiftly sweeps your feet out from beneath you with (?:.+) before driving the point of the weapon into your (?:right|left) leg\.$]], { "sentinel" } }, -- wsys
    { [[^([\w'\-]+) draws (?:.+) in an expert lateral slice across your (?:.+)\.$]], { "sentinel" } }, -- wsys
    { [[^([\w'\-]+) viciously lacerates your (?:.+) with (?:.+)\.$]], { "sentinel" } }, -- wsys
    { [[^([\w'\-]+) viciously gouges your \.+ with \.+\.$]], { "sentinel" } }, -- wsys
    { [[^([\w'\-]+) pricks you twice in rapid succession with \w+ dirk\.?$]], { "serpent" } }, -- wsys
    { [[^([\w'\-]+) flays the (?:sileris|quicksilver) coating from you\.$]], { "serpent" } }, -- wsys
    { [[^([\w'\-]+) flays away your aura of rebounding defence\.$]], { "serpent" } }, -- wsys
    { [[^With a pop of \w+ knuckles, ([\w'\-]+) buries \w+ foot under your back and flips you over onto your stomach\.$]], { "serpent" } }, -- wsys
    { [[^([\w'\-]+) leaps from the shadows and plunges a dagger into your unsuspecting back!$]], { "serpent" } }, -- wsys
    { [[^([\w'\-]+) points a finger at you and you feel anti-magic sweep over you.$]], { "serpent" } }, -- wsys
    { [[^([\w'\-]+) hunches \w+ shoulders and lets out a soft hiss\.$]], { "serpent" }, acted = false }, -- wsys
    { [[^([\w'\-]+) forms a ball of light in \w+ palm and hurls it \w+\.$]], { "serpent" }, acted = false }, -- wsys
    { [[^The outline of ([\w'\-]+) fades away to the \w+\.$]], { "serpent" }, acted = false }, -- wsys
    { [[^([\w'\-]+) slips behind .+ and garrotes \w+ with \w+ whip\.$]], { "serpent" }, acted = false }, -- wsys
    { [[^With an appraising glance at you, ([\w'\-]+) shapes the arms and legs of a \w+ doll\.$]], { "shaman" } }, -- wsys
    { [[^([\w'\-]+)'s eyes flutter and close as (?:he|she|fae) begins to rock back and forth, chanting ominously under (?:his|her|faes) breath\.$]], { "shaman" } }, -- wsys
    { [[^([\w'\-]+) gestures sharply in your direction with one hand, and invisible whips viciously lash at you\.$]], { "sylvan" } }, -- wsys
    { [[^([\w'\-]+) summons a blade of condensed air and shears cleanly through the magical shield surrounding you\.$]], { "sylvan" } }, -- wsys
    { [[^([\w'\-]+) raises (?:his|her|faes) hands above (?:his|her|faes) head, gaze focused intently upon you\. Moments later, a single lightning bolt streaks down from above, slamming into you with an explosion of brilliant power\.$]], { "sylvan" } }, -- wsys
    { [[^Sweat breaking out on the forehead of ([\w'\-]+) is your only warning before a bolt of lightning leaps down from on high, slamming into you and electrifying every nerve in a synchronised wave of agony\.$]], { "sylvan" } }, -- wsys
    { [[^([\w'\-]+) negligently waves (?:his|her|faes) hand in your direction, conjuring forth a hailstone which strikes you sharply in the side of the head\.$]], { "sylvan" } }, -- wsys
    { [[^Drawing \w+ up to \w+ full height, ([\w'\-]+) throws (?:his|her|faes) arms wide\. The clouds above roil, then bolt after bolt of incandescent lightning falls upon you\. The world becomes nothing but light and pain\.$]], { "sylvan" } }, -- wsys
    { [[^Your ears are abruptly filled with the shockingly loud clap of nearby thunder, summoned forth by ([\w'\-]+)\.$]], { "sylvan" } }, -- wsys
    { [[^More a physical blow than a simple sound, the shocking thunderclap summoned forth by ([\w'\-]+) leaves you reeling\.$]], { "sylvan" } }, -- wsys
    { [[^([\w'\-]+) thrusts one hand in your direction and a vicious wind is summoned forth, viciously lacerating you\.$]], { "sylvan" } }, -- wsys
    { [[^([\w'\-]+) whispers words so anathema to you that you feel your mind fracturing at the very knowing, each twisted syllable threatening to sweep away the very essence that composes you\.$]], { "unnamable" } }, -- wsys
    { [[^\w+ eyes rolling back in \w+ skull, ([\w'\-]+) opens \w+ true mouth and speaks something so unnatural that your entire body rebels against the horror given voice\.$]], { "unnamable" } }, -- wsys
    { [[^([\w'\-]+) croons to you of things too horrific to contemplate, of nightmares made real, each of (?:his|her|faes) myriad mouths joined in profane chorus\.$]], { "unnamable" } }, -- wsys
    { [[^A wall of sound slams into you, a terrible symphony of something undescribably wrong as each of the mouths that have torn open upon the body of ([\w'\-]+) howl in silent wrath\.$]], { "unnamable" } }, -- wsys
    { [[^The myriad mouths that have torn open upon the body of ([\w'\-]+) croon in profane symphony to you, a choir of entropic whispers which sets your bones to shuddering\.$]], { "unnamable" } }, -- wsys
    { [[^Each of the mouths that have torn open upon the body of ([\w'\-]+) croon softly to you, of theduality, of the twisted reflection, of that which lies without and within\.$]], { "unnamable" } }, -- wsys
    { [[^You recoil from ([\w'\-]+), clapping your hands over your ears to block out the maddening whispers\.$]], { "unnamable" } }, -- wsys
    { [[^The profane presence of ([\w'\-]+) washes over you, and your courage is torn asunder\.$]], { "unnamable" } }, -- wsys
    { [[^The profane nature of ([\w'\-]+) becomes too much to withstand\.$]], { "unnamable" } }, -- wsys
    { [[^The amorphous form of ([\w'\-]+) trembles, some of the liquid composing it falling away from the greater whole\.$]], { "waterlord" } }, -- wsys
    { [[^([\w'\-]+) skilfully whirls .+ toward you(?:r (?:left arm|right arm|left leg|right leg|torso|head))?\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- wsys
    { [[^([\w'\-]+) ducks low and smashes (?:his|her|faes) shield into your knees, causing them to buckle underneath you\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- wsys
    { [[^([\w'\-]+) quickly lunges to the side, bringing (?:\w+) shield around to smash into your spine\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- wsys
    { [[^([\w'\-]+) drives the edge of (?:\w+) shield into your throat, cutting off your air supply\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- wsys
    { [[^([\w'\-]+) unleashes a terrible blow at you(?:r (?:left arm|right arm|left leg|right leg|torso|head))? with .+\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- wsys
    { [[^([\w'\-]+) drops into a low crouch, sweeping (?:.+) beneath your guard and tangling it with your legs\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- wsys
    { [[^Lightning-quick, ([\w'\-]+) jabs you with a \w+\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- wsys
    { [[^Lightning-quick, ([\w'\-]+) jabs your .+ with a \w+\.$]], { "infernal", "paladin", "runewarden", "unnamable" } }, -- wsys
}
