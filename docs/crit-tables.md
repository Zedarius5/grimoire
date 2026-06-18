# GemStone IV Critical Hit Tables — Grimoire reference
_Generated 2026-06-17 from gswiki `?action=raw`. Source of truth for the elemental damage highlight groups._

Each element has two highlight groups in Grimoire: **`<Element> damage`** (foreground tint) and
**`<Element> fatal`** (foreground + background). A rule is a distinctive *substring* of the message;
the group highlights the whole line. **Fatal** = the wiki marks the row `F`/`Fatal`. The
**match** column is the substring Grimoire currently uses (blank = not yet matched).

Variable bits in messages: `[target]` = creature name; the game also inserts the creature at
possessives / after prepositions / after semicolons, so literal rules use a creature-free run.


## Fire  (130 messages, 20 fatal)

| sec | rank | F | message | current match |
|---|---|---|---|---|
| HEAD | 0 |  | Blast of hot air to head dries foe's hair. | Blast of hot air to head dries foe's hair |
| HEAD | 5 |  | Minor burns to head. That hurts a bit. | Minor burns to head |
| HEAD | 10 |  | Burst of flames to head catches ears on fire! Yeeoww! | Burst of flames to head catches ears on fire |
| HEAD | 15 |  | Burst of flames char forehead a crispy black. | Burst of flames char forehead a crispy black |
| HEAD | 20 |  | Flames engulf head searing hair and scalp. Sickening! | Flames engulf head searing hair and scalp |
| HEAD | 25 |  | Flames incinerate scalp completely and blacken scullcap. | Flames incinerate scalp completely and blacken scullcap |
| HEAD | 30 | F | Head explodes in flames! Grab some marshmallows. | Head explodes in flames |
| HEAD | 35 | F | Flame sets a [target]'s head alight like a torch. Burned beyond recognition. | Burned beyond recognition |
| HEAD | 40 | F | Head reduced to a charred stump. | Head reduced to a charred stump |
| HEAD | 50 | F | Head explodes, splattering sizzling bits of flesh and bone everywhere. | Head explodes, splattering sizzling bits of flesh and bone everywhere |
| NECK | 0 |  | Flames brush foe's neck. Some sweat but not much else. | Some sweat but not much else |
| NECK | 2 |  | Minor burns to neck. Looks uncomfortable. | Looks uncomfortable |
| NECK | 5 |  | Burst of flames to neck. Yuck! | Burst of flames to neck |
| NECK | 10 |  | Burst of flames chars neck a crispy black. | Burst of flames chars neck a crispy black |
| NECK | 12 |  | Flames incinerate muscle tissue in neck exposing trachea. More than you ever wanted to see. | More than you ever wanted to see |
| NECK | 15 |  | Flames burn neck into a bubbling mass of flesh. Forget lunch. | Forget lunch |
| NECK | 20 | F | Fire burns through neck and destroys carotid artery. Painfully bloody way to die. | Painfully bloody way to die |
| NECK | 25 | F | A [target] takes a breath of super-heated air and expires gasping. | takes a breath of super-heated air and expires gasping |
| NECK | 30 | F | Neck consumed in flame and charred to a crisp. | Neck consumed in flame and charred to a crisp |
| NECK | 40 | F | Neck completely incinerated; head drops to the ground and rolls to your feet! | Neck completely incinerated; head drops to the ground and rolls to your feet |
| RIGHT EYE | 0 |  | Flames tickle right eye. Eyebrow singed. | Eyebrow singed |
| RIGHT EYE | 1 |  | Minor burns to right eye. Foe blinks back the tears. | Foe blinks back the tears |
| RIGHT EYE | 3 |  | Burst of flames to right eye bakes eyelid. | eye bakes eyelid |
| RIGHT EYE | 5 |  | Burst of flames to right eye incinerates eyelid. Gruesome. | eye incinerates eyelid |
| RIGHT EYE | 10 |  | Horrid burns seal right eye. Consider an eyepatch. | Consider an eyepatch |
| RIGHT EYE | 20 |  | Flames toast right cornea. Consider an eyepatch. | Consider an eyepatch |
| RIGHT EYE | 30 |  | Right eye propelled out of socket by fiery explosion! | eye propelled out of socket by fiery explosion |
| RIGHT EYE | 40 | F | Right eye catches fire, quickly bringing [target]'s brain to a boil. | eye catches fire, quickly bringing |
| RIGHT EYE | 45 | F | Right eye evaporates in a burst of flame. Death from shock follows. | eye evaporates in a burst of flame |
| RIGHT EYE | 50 | F | Super-heated flame causes right eye to explode inward. | right eye to explode inward |
| LEFT EYE | 0 |  | Flames tickle left eye. Eyebrow singed. | Eyebrow singed |
| LEFT EYE | 1 |  | Minor burns to left eye. Foe blinks back the tears. | Foe blinks back the tears |
| LEFT EYE | 3 |  | Burst of flames to left eye bakes eyelid. | eye bakes eyelid |
| LEFT EYE | 5 |  | Burst of flames to left eye incinerates eyelid. Gruesome. | eye incinerates eyelid |
| LEFT EYE | 10 |  | Horrid burns seal left eye. Consider an eyepatch. | Consider an eyepatch |
| LEFT EYE | 20 |  | Flames toast left cornea. Consider an eyepatch. | Consider an eyepatch |
| LEFT EYE | 30 |  | Left eye propelled out of socket by fiery explosion! | eye propelled out of socket by fiery explosion |
| LEFT EYE | 40 | F | Flame engulfs foe's left eye, setting it ablaze. Mercifully, death follows quickly. | Mercifully, death follows quickly |
| LEFT EYE | 45 | F | Intense heat causes left eye to evaporate. Death from shock is unavoidable. | Death from shock is unavoidable |
| LEFT EYE | 50 | F | Left eye explodes. Sizzling pieces of brain drip from the empty socket. | eye explodes |
| CHEST | 0 |  | Burst of flames to chest. Didn't hurt much. | Didn't hurt much |
| CHEST | 5 |  | Minor burns to chest. That hurts a bit. | Minor burns to chest |
| CHEST | 10 |  | Burst of flames to chest toasts skin nicely. | Burst of flames to chest toasts skin nicely |
| CHEST | 15 |  | Burst of flames char chest a crisp black. | Burst of flames char chest a crisp black |
| CHEST | 20 |  | Nasty burns to chest make you wish you never heard of heartburn. | Nasty burns to chest make you wish you never heard of heartburn |
| CHEST | 25 |  | Flames burn hole in chest exposing ribs. | Flames burn hole in chest exposing ribs |
| CHEST | 30 |  | Flames cook a [target]'s chest. Looks about medium well. | Looks about medium well |
| CHEST | 50 |  | Skin and some muscle burnt off chest. | Skin and some muscle burnt off chest |
| CHEST | 60 | F | Flames engulf body. Chest left a smoldering ruin. | Flames engulf body |
| CHEST | 70 | F | Fire completely surrounds [target]. Blood boils and heart stops. | Blood boils and heart stops |
| ABDOMEN | 0 |  | Burst of flames to abdomen. Didn't hurt much. | Didn't hurt much |
| ABDOMEN | 5 |  | Minor burns to abdomen. Looks painful. | Looks painful |
| ABDOMEN | 10 |  | Burst of flames to abdomen toasts skin nicely. | Burst of flames to abdomen toasts skin nicely |
| ABDOMEN | 15 |  | Burst of flames chars abdomen a crispy black. | Burst of flames chars abdomen a crispy black |
| ABDOMEN | 20 |  | Nasty burns to abdomen, [target] shrieks in pain! | shrieks in pain |
| ABDOMEN | 25 |  | Abdomen bursts into flames. Would be funny without the blood. | Would be funny without the blood |
| ABDOMEN | 30 |  | Flames cook [target]'s abdomen. Looks about medium well. | Looks about medium well |
| ABDOMEN | 50 |  | Permanently debilitating burns across stomach. | Permanently debilitating burns across stomach |
| ABDOMEN | 60 | F | Intestines rupture from intense heat; dies a slow, painful death. | Intestines rupture from intense heat; dies a slow, painful death |
| ABDOMEN | 70 | F | Flame burns through abdomen. Greasy smoke billows forth. | Greasy smoke billows forth |
| BACK | 0 |  | Blast of flames to back. More bother than pain. | More bother than pain |
| BACK | 5 |  | Minor burns to back. Looks uncomfortable. | Looks uncomfortable |
| BACK | 10 |  | Burst of flames to back toasts skin nicely. | Burst of flames to back toasts skin nicely |
| BACK | 15 |  | Burst of flames to back fries shoulder blades. | Burst of flames to back fries shoulder blades |
| BACK | 20 |  | Nasty burns to back. Won't be sleeping on that for awhile. | Won't be sleeping on that for awhile |
| BACK | 25 |  | Back bursts into a spectacular display of flames. Bet it hurts too. | Back bursts into a spectacular display of flames |
| BACK | 30 |  | Flames cook [target]'s back. Looks about medium well. | Looks about medium well |
| BACK | 50 |  | A large patch of flesh is seared off [target]'s back. | A large patch of flesh is seared off |
| BACK | 60 | F | Flame engulfs back: [target] flambe! | Flame engulfs back |
| BACK | 70 | F | Back burnt to the bone. Smoke curls up from what's left.. | Smoke curls up from what's |
| RIGHT ARM | 0 |  | Flames tickle right arm. Hair singed. | Flames tickle |
| RIGHT ARM | 3 |  | Minor burns to right arm. That hurts a bit. |  |
| RIGHT ARM | 7 |  | Burst of flames to right arm burns skin bright red. | arm burns skin bright red |
| RIGHT ARM | 8 |  | Burst of flames to right arm toasts skin to elbows. | arm toasts skin to elbows |
| RIGHT ARM | 10 |  | Nasty burns to right arm. Gonna need lots of butter. | Gonna need lots of butter |
| RIGHT ARM | 15 |  | Flames incinerate right arm to the bone. Not a pleasant sight. | Not a pleasant sight |
| RIGHT ARM | 20 |  | Extreme heat causes [target]'s right arm to expand and snap. That must hurt! | arm to expand and snap |
| RIGHT ARM | 25 |  | Right arm scorched so bad it might as well be gone. | arm scorched so bad it might as well be gone |
| RIGHT ARM | 35 |  | Right forearm burned clean off. At least it's cauterized. | forearm burned clean off |
| RIGHT ARM | 40 |  | Flame consumes [target]'s right arm all the way to the shoulder. | arm all the way to the shoulder |
| LEFT ARM | 0 |  | Flames tickle left arm. Hair singed. | Flames tickle |
| LEFT ARM | 3 |  | Minor burns to left arm. That hurts a bit. |  |
| LEFT ARM | 7 |  | Burst of flames to left arm burns skin bright red. | arm burns skin bright red |
| LEFT ARM | 8 |  | Burst of flames to left arm toasts skin to elbows. | arm toasts skin to elbows |
| LEFT ARM | 10 |  | Nasty burns to left arm. Gonna need lots of butter. | Gonna need lots of butter |
| LEFT ARM | 15 |  | Flames incinerate left arm to the bone. Not a pleasant sight. | Not a pleasant sight |
| LEFT ARM | 20 |  | Extreme heat causes [target]'s left arm to expand and snap. That must hurt! | arm to expand and snap |
| LEFT ARM | 25 |  | Blaze chars [target]'s left arm. What's left is unusable. |  |
| LEFT ARM | 35 |  | Left arm burnt away at elbow. Ointment won't help. | arm burnt away at elbow |
| LEFT ARM | 40 |  | Left arm incinerated. Unfortunate. | arm incinerated |
| RIGHT HAND | 0 |  | Burst of flame to right hand singes knuckles. | hand singes knuckles |
| RIGHT HAND | 1 |  | Minor burns to right hand. Ouch! |  |
| RIGHT HAND | 3 |  | Burst of flames to right hand burns fingers bright red. | hand burns fingers bright red |
| RIGHT HAND | 5 |  | Burst of flames to right hand fries palm. Ouch! | Burst of flames |
| RIGHT HAND | 7 |  | Nasty burns to right hand. Gonna need lots of butter. | Gonna need lots of butter |
| RIGHT HAND | 8 |  | Right hand fried to a crisp. Think barbecue sauce. | hand fried to a crisp |
| RIGHT HAND | 10 |  | Extreme heat melts the skin off [target]'s right hand. Gross! | Extreme heat melts the skin off |
| RIGHT HAND | 15 |  | Skin and muscle seared off right hand. Not much left. | Skin and muscle seared off |
| RIGHT HAND | 25 |  | Right hand reduced to smoking ash. Too bad would have come in handy. | Too bad would have come in handy |
| RIGHT HAND | 30 |  | Unbelievable heat melts hand down to the wrist. | Unbelievable heat melts hand down to the wrist |
| LEFT HAND | 0 |  | Burst of flame to left hand singes knuckles. | hand singes knuckles |
| LEFT HAND | 1 |  | Minor burns to left hand. Ouch! |  |
| LEFT HAND | 3 |  | Burst of flames to left hand burns fingers bright red. | hand burns fingers bright red |
| LEFT HAND | 5 |  | Burst of flames to left hand fries palm. Ouch! | Burst of flames |
| LEFT HAND | 7 |  | Nasty burns to left hand. Gonna need lots of butter. | Gonna need lots of butter |
| LEFT HAND | 8 |  | Left hand fried to a crisp. Think barbecue sauce. | hand fried to a crisp |
| LEFT HAND | 10 |  | Extreme heat melts the skin off [target]'s left hand. Gross! | Extreme heat melts the skin off |
| LEFT HAND | 15 |  | Several fingers consumed from left hand. The rest are unusable. | Several fingers consumed |
| LEFT HAND | 25 |  | Flame burns everything but the bones from left hand. | Flame burns everything but the bones |
| LEFT HAND | 30 |  | Left hand burned off. Only a stump remains. | Only a stump remains |
| RIGHT LEG | 0 |  | Flames tickle right leg. Feels warm. | Flames tickle |
| RIGHT LEG | 5 |  | Minor burns to right leg. That hurts a bit. |  |
| RIGHT LEG | 10 |  | Burst of flames to right leg burns skin bright red. | leg burns skin bright red |
| RIGHT LEG | 15 |  | Burst of flames to right leg blackens kneecap. | leg blackens kneecap |
| RIGHT LEG | 17 |  | Nasty burns to right leg. Gonna need lots of butter. | Gonna need lots of butter |
| RIGHT LEG | 20 |  | Flames incinerate right leg to the bone. Not a pleasant sight. | Not a pleasant sight |
| RIGHT LEG | 25 |  | Extreme heat causes right leg to expand and snap. That must hurt! | leg to expand and snap |
| RIGHT LEG | 30 |  | Right leg horribly scorched. Won't be usable for weeks. | Won't be usable for weeks |
| RIGHT LEG | 40 |  | The lower half of [target]'s right leg is almost completely burned away. | leg is almost completely burned away |
| RIGHT LEG | 45 |  | Right leg aflame. When the smoke clears, there's nothing left. | When the smoke clears, there's nothing |
| LEFT LEG | 0 |  | Flames tickle left leg. Feels warm. | Flames tickle |
| LEFT LEG | 5 |  | Minor burns to left leg. That hurts a bit. |  |
| LEFT LEG | 10 |  | Burst of flames to left leg burns skin bright red. | leg burns skin bright red |
| LEFT LEG | 15 |  | Burst of flames to left leg blackens kneecap. | leg blackens kneecap |
| LEFT LEG | 17 |  | Nasty burns to left leg. Gonna need lots of butter. | Gonna need lots of butter |
| LEFT LEG | 20 |  | Flames incinerate left leg to the bone. Not a pleasant sight. | Not a pleasant sight |
| LEFT LEG | 25 |  | Extreme heat causes left leg to expand and snap. That must hurt! | leg to expand and snap |
| LEFT LEG | 30 |  | Scorching heat shrivels left leg to a useless black mass. | leg to a useless black mass |
| LEFT LEG | 40 |  | Left leg burned off at the knee.  Ouch. | leg burned off at the knee |
| LEFT LEG | 45 |  | Left leg completely charred. | leg completely charred |

## Cold  (130 messages, 22 fatal)

| sec | rank | F | message | current match |
|---|---|---|---|---|
| HEAD | 0 |  | Cool breeze!  Hear it whistling through the [target]'s ears? | Hear it whistling |
| HEAD | 5 |  | Chilly blast to the head.  Bet the [target]'s ears are tingling! | Chilly blast to the head |
| HEAD | 10 |  | Cold blast to the ears.  The [target] should have worn a hat! | Cold blast to the ears |
| HEAD | 15 |  | Icy blast to the head and the [target] is reeling! | Icy blast to the head |
| HEAD | 20 |  | Solid blow to the head exposes grey matter on ice! | Solid blow to the head exposes grey matter on ice |
| HEAD | 25 |  | Massive strike of icy shards shatters the [target]'s skull! | Massive strike of icy shards shatters |
| HEAD | 30 | F | The [target] gets a glassy look in its eyes as blast connects solidly... or is that an icy stare? | gets a glassy look in its eyes as blast connects solidly |
| HEAD | 35 | F | Head freezes solid and the [target] topples over, shattering skull on impact. | topples over, shattering skull on impact |
| HEAD | 40 | F | Icy shards bombard the [target]'s head and exit its ear, leaving little behind! | head and exit its ear, leaving little behind |
| HEAD | 50 | F | Freezing blast turns facial features a stunning, but very unhealthy shade of blue. | Freezing blast turns facial features a stunning, but very unhealthy shade of blue |
| NECK | 0 |  | A cool breeze brushes the nape of the [target]'s neck. | A cool breeze brushes the nape |
| NECK | 2 |  | A frosty blow to the neck.  Bet that smarts! | A frosty blow to the neck.  Bet that smarts |
| NECK | 5 |  | Ouch!  What a stiff neck. | Ouch!  What a stiff neck |
| NECK | 10 |  | Stiff blast of icy air to neck! | Stiff blast of icy air to neck |
| NECK | 12 |  | Frigid blast rearranges the [target]'s neck. | Frigid blast rearranges the |
| NECK | 15 |  | Slivers of ice slice the [target]'s throat into ribbons of flesh and blood! | throat into ribbons of flesh and blood |
| NECK | 20 | F | Icy blast to neck freezes the [target]'s words in mid-speech and leaves it speechless...permanently! | words in mid-speech and leaves it speechless...permanently |
| NECK | 25 | F | Base of skull frozen, removing any feeling from the neck down.  The [target] lives just long enough to realize a painless death! | lives just long enough to realize a painless death |
| NECK | 30 | F | Icy shards slice through the [target]'s neck...leaving breathing no longer necessary -- or possible! | neck...leaving breathing no longer necessary -- or possible |
| NECK | 40 | F | Blast to neck causes the [target] to jerk with pain.  Unfortunately that snaps the now frozen neck like an icicle! | to jerk with pain.  Unfortunately that snaps the now frozen neck like an icicle |
| RIGHT EYE | 0 |  | Frost forms on the [target]'s right eyebrow, aging it a bit. | eyebrow, aging it a bit |
| RIGHT EYE | 1 |  | Near miss!  Ice particles sting the [target]'s eye and it blinks rapidly. | Near miss!  Ice particles sting |
| RIGHT EYE | 3 |  | Chilly blast to the right eye leaves the [target] in tears. | Chilly blast to the right eye leaves |
| RIGHT EYE | 5 |  | Cold compresses will help the swelling of the [target]'s right eye! | Cold compresses will help the swelling |
| RIGHT EYE | 10 |  | Icy bolt to the right eye!  Ouch!  Ice cream headache! | Icy bolt to the right eye!  Ouch!  Ice cream headache |
| RIGHT EYE | 20 |  | A frigid attack leaves the [target] blinded in its right eye.  Bet it didn't see it coming! | Bet it didn't see it coming |
| RIGHT EYE | 30 | F | Icy blast blinds the [target]'s eye.  But it won't need eyes anyway! | But it won't need eyes anyway |
| RIGHT EYE | 30 | F | Wicked slash of frigid energy shatters right eye into a thousand tiny particles!  Penetration to the brain causes instant death! | Penetration to the brain causes instant death |
| RIGHT EYE | 45 | F | Failed to evade blast!  Eye and brain splintered beyond recognition. | Eye and brain splintered beyond recognition |
| RIGHT EYE | 50 | F | Fatal strike to the right eye!  Brain frozen and so is the [target]! | Brain frozen and so is |
| LEFT EYE | 0 |  | Frost forms on the [target]'s left eyebrow, aging it a bit. | eyebrow, aging it a bit |
| LEFT EYE | 1 |  | Near miss!  Ice particles sting the [target]'s eye and it blinks rapidly. | Near miss!  Ice particles sting |
| LEFT EYE | 3 |  | Chilly blast to the left eye leaves the [target] in tears. | Chilly blast to the left eye leaves |
| LEFT EYE | 5 |  | Cold compresses will help the swelling of the [target]'s left eye! | Cold compresses will help the swelling |
| LEFT EYE | 10 |  | Icy bolt to the left eye!  Ouch!  Ice cream headache! | Icy bolt to the left eye!  Ouch!  Ice cream headache |
| LEFT EYE | 20 |  | A frigid attack leaves the [target] blinded in its left eye.  Bet it didn't see it coming! | Bet it didn't see it coming |
| LEFT EYE | 30 | F | Icy blast blinds the [target]'s eye.  But it won't need eyes anyway! | But it won't need eyes anyway |
| LEFT EYE | 30 | F | Wicked slash of frigid energy shatters left eye into a thousand tiny particles!  Penetration to the brain causes instant death! | Penetration to the brain causes instant death |
| LEFT EYE | 45 | F | Failed to evade blast!  Eye and brain splintered beyond recognition. | Eye and brain splintered beyond recognition |
| LEFT EYE | 50 | F | Fatal strike to the left eye!  Brain frozen and so is the [target]! | Brain frozen and so is |
| CHEST | 0 |  | The [target] looks slightly uncomfortable. | looks slightly uncomfortable |
| CHEST | 5 |  | Chilly blast to the chest causes heart to skip a beat. | Chilly blast to the chest causes heart to skip a beat |
| CHEST | 10 |  | A chilly blast strikes the [target] in the chest, knocking him back a step. | in the chest, knocking him back a step |
| CHEST | 15 |  | The [target] failed to sidestep the chilly blast.  Bruised ribs anyone? | failed to sidestep the chilly blast |
| CHEST | 20 |  | Darn!  Frozen ribs take longer to cook, and broken ones to boot! | Frozen ribs take longer to cook, and broken ones to boot |
| CHEST | 25 |  | Solid blast of ice square to the chest rocks the [target] back on its heels! | Solid blast of ice square to the chest rocks |
| CHEST | 30 |  | Freezing blast opens a gaping hole in the [target]'s chest! | Freezing blast opens a gaping hole |
| CHEST | 30 |  | Brrrrr!  That was a cold blow to the chest! | Brrrrr!  That was a cold blow to the chest |
| CHEST | 60 | F | The [target] drops in its tracks as the bitter cold freezes its lungs solid! | drops in its tracks as the bitter cold freezes its lungs solid |
| CHEST | 70 | F | Icy blast deep freezes one perfectly good heart! | Icy blast deep freezes one perfectly good heart |
| ABDOMEN | 0 |  | The [target] barely notices the cool burst of energy. | barely notices the cool burst of energy |
| ABDOMEN | 5 |  | Icy chill to the [target]'s midriff.  Looks like a bowl of nice hot stew is in order. | midriff.  Looks like a bowl of nice hot stew is in order |
| ABDOMEN | 10 |  | A chilly blow to the stomach winds the [target]! | A chilly blow to the stomach winds |
| ABDOMEN | 15 |  | The icy blast tears into the [target]'s stomach! | The icy blast tears |
| ABDOMEN | 20 |  | A gallant effort to elude the blast, but you got the [target] in the hip! | A gallant effort to elude the blast, but you got |
| ABDOMEN | 25 |  | Pieces of an icy substance slice the [target]'s abdomen to shreds! | Pieces of an icy substance slice |
| ABDOMEN | 30 |  | A frigid burst of energy to the stomach leaves the [target] reeling. | A frigid burst of energy to the stomach leaves |
| ABDOMEN | 30 |  | The [target] reels from a direct hit to the stomach.  No food for a while! | reels from a direct hit to the stomach |
| ABDOMEN | 60 | F | The [target] fails to avoid the icy blast and that, as the story goes, is it! | fails to avoid the icy blast and that, as the story goes, is it |
| ABDOMEN | 70 | F | Belly is now a block of ice. So much for breakfast! | Belly is now a block of ice |
| BACK | 0 |  | A slight shiver runs down the [target]'s back. | A slight shiver runs down |
| BACK | 5 |  | My! It looks like the [target] will be stiff in the morning! Better ice down the bruises! | will be stiff in the morning |
| BACK | 10 |  | An icy blast to the back!  Sleeping will not be easy tonight. | An icy blast to the back!  Sleeping will not be easy tonight |
| BACK | 15 |  | Near miss!  Cool blast to the lower back and the [target] staggers. | Cool blast to the lower back |
| BACK | 20 |  | Icy strike to the back scores a direct hit! | Icy strike to the back scores a direct hit |
| BACK | 25 |  | Strange how the cold can burn. | Strange how the cold can burn |
| BACK | 30 |  | Ouch!  Slivers of ice in the strike easily penetrate to the [target]'s spine. | Slivers of ice in the strike easily penetrate |
| BACK | 30 |  | An icy slash across the lower back slices deep into the [target]'s muscle! | An icy slash across the lower back slices deep |
| BACK | 60 | F | Deadly accurate hit!  The [target]'s back is shattered into icy oblivion! | back is shattered into icy oblivion |
| BACK | 70 | F | Deadly accuracy shatters the [target]'s spine into a thousand tiny icy shards! | spine into a thousand tiny icy shards |
| RIGHT ARM | 0 |  | Cool touch!  Look at the goosebumps! | Look at the goosebumps |
| RIGHT ARM | 3 |  | The [target] winces at the cold blast to the right arm. | winces at the cold blast |
| RIGHT ARM | 7 |  | The [target] just got the cold shoulder! | just got the cold shoulder |
| RIGHT ARM | 8 |  | The [target]'s right arm trembles with the cold. | arm trembles with the cold |
| RIGHT ARM | 10 |  | Cold blast rends muscles from bone! | Cold blast rends muscles from bone |
| RIGHT ARM | 15 |  | Right arm shattered by an extremely well placed hit! | arm shattered by an extremely well placed hit |
| RIGHT ARM | 20 |  | The [target] pales as your chillingly accurate shot penetrates to the bone. | pales as your chillingly accurate shot penetrates to the bone |
| RIGHT ARM | 25 |  | Icy blast takes right arm off at the shoulder! | arm off at the shoulder |
| RIGHT ARM | 35 |  | Weapon arm freeze-dried!  Add water and stir. | Weapon arm freeze-dried!  Add water and stir |
| RIGHT ARM | 40 |  | Advanced case of frostbite removes right arm at the shoulder! | Advanced case of frostbite removes right arm at the shoulder |
| LEFT ARM | 0 |  | Cool touch!  Look at the goosebumps! | Look at the goosebumps |
| LEFT ARM | 3 |  | The [target] winces at the cold blast to the left arm. | winces at the cold blast |
| LEFT ARM | 7 |  | The [target] just got the cold shoulder! | just got the cold shoulder |
| LEFT ARM | 8 |  | The [target]'s left arm trembles with the cold. | arm trembles with the cold |
| LEFT ARM | 10 |  | Left arm is shattered by cold blast! | arm is shattered by cold blast |
| LEFT ARM | 15 |  | Left arm fractured by an icy blast! | arm fractured by an icy blast |
| LEFT ARM | 20 |  | Boiling water would feel better than that! | Boiling water would feel better than that |
| LEFT ARM | 25 |  | The [target]'s left arm is shattered beyond recognition by frigid blow. | arm is shattered beyond recognition by frigid blow |
| LEFT ARM | 35 |  | Oops.  Shield arm freeze-dried! | Oops.  Shield arm freeze-dried |
| LEFT ARM | 40 |  | Advanced case of frostbite and shield arm is history! | Advanced case of frostbite and shield arm is history |
| RIGHT HAND | 0 |  | Cold hands, warm heart! | Cold hands, warm heart |
| RIGHT HAND | 1 |  | The [target]'s right hand turns an interesting shade of light blue. | hand turns an interesting shade of light blue |
| RIGHT HAND | 3 |  | Almost missed!  A pair of gloves would have helped! | Almost missed!  A pair of gloves would have helped |
| RIGHT HAND | 5 |  | The [target] jumps back as your chilly attack bruises its weapon hand! | jumps back as your chilly attack bruises its weapon hand |
| RIGHT HAND | 8 |  | Icy blast freezes the [target]'s right hand! | Icy blast freezes the |
| RIGHT HAND | 10 |  | Nice Strike!  The [target]'s fingers snap as its right hand freezes solid. | hand freezes solid |
| RIGHT HAND | 10 |  | The [target] grimaces as your attack fractures its right wrist. | grimaces as your attack fractures |
| RIGHT HAND | 10 |  | Polar blast decimates the [target]'s right hand! | Polar blast decimates the |
| RIGHT HAND | 25 |  | Right hand freezes solid before falling off!  Say hello to Lefty! | hand freezes solid before falling off |
| RIGHT HAND | 30 |  | Frigid blast renders the [target]'s right hand useless - missing even! | hand useless - missing even |
| LEFT HAND | 0 |  | Cold hands, warm heart! | Cold hands, warm heart |
| LEFT HAND | 1 |  | The [target]'s left hand turns an interesting shade of light blue. | hand turns an interesting shade of light blue |
| LEFT HAND | 3 |  | Almost missed!  Bet the [target] wants warm pockets now. | wants warm pockets now |
| LEFT HAND | 5 |  | The [target] jumps back as your chilly attack bruises his left hand! | jumps back as your chilly attack bruises |
| LEFT HAND | 8 |  | Icy blast freezes the [target]'s left hand! | Icy blast freezes the |
| LEFT HAND | 10 |  | Nice Strike!  The [target]'s fingers snap as its left hand freezes solid. | hand freezes solid |
| LEFT HAND | 10 |  | The [target] grimaces as your attack fractures its left wrist. | grimaces as your attack fractures |
| LEFT HAND | 10 |  | Polar blast decimates the [target]'s left hand! | Polar blast decimates the |
| LEFT HAND | 25 |  | Hand freezes solid before falling off!  Who needs a left hand anyway? | Hand freezes solid before falling off!  Who needs a left hand anyway |
| LEFT HAND | 30 |  | Frigid blast renders the [target]'s left hand useless - missing even! | hand useless - missing even |
| RIGHT LEG | 0 |  | A cool breeze brushes the [target]'s right leg, barely raising a hair. | leg, barely raising a hair |
| RIGHT LEG | 5 |  | Brrrr!  That was a good hit to the right leg!  Knocked the [target] silly. | That was a good hit |
| RIGHT LEG | 10 |  | The [target] appears to be getting cold feet. | appears to be getting cold feet |
| RIGHT LEG | 15 |  | The [target] dances as the blast of cold air contacts heretofore warm toes. | dances as the blast of cold air contacts heretofore warm toes |
| RIGHT LEG | 17 |  | Blast of cold air to right knee causes a polar knee cap! | knee causes a polar knee cap |
| RIGHT LEG | 20 |  | The [target] staggers as your icy attack shatters its right leg. | staggers as your icy attack shatters |
| RIGHT LEG | 25 |  | Pain fills the [target]'s face as its right ankle shatters from the icy blast. | ankle shatters from the icy blast |
| RIGHT LEG | 30 |  | What was once the [target]'s right leg shatters with your well placed strike! | leg shatters with your well placed strike |
| RIGHT LEG | 40 |  | A freezing and accurate strike renders the [target]'s right leg a fond memory! | A freezing and accurate strike renders |
| RIGHT LEG | 45 |  | Frigid blast shatters the [target]'s right leg beyond all recognition! | leg beyond all recognition |
| LEFT LEG | 0 |  | A cool breeze brushes the [target]'s left leg, barely raising a hair. | leg, barely raising a hair |
| LEFT LEG | 5 |  | Brrrr!  That was a good hit to the left leg!  Knocked the [target] silly. | Brrrr!  That was a good hit to the left leg!  Knocked |
| LEFT LEG | 10 |  | The [target] looks as if a hot foot would feel good about now! | looks as if a hot foot would feel good about now |
| LEFT LEG | 10 |  | The [target] falters as a chill blast of air strikes its left leg! | falters as a chill blast of air strikes |
| LEFT LEG | 17 |  | Blast of cold air to left knee causes a polar knee cap! | knee causes a polar knee cap |
| LEFT LEG | 20 |  | The [target] staggers as your icy attack shatters its left leg. | staggers as your icy attack shatters |
| LEFT LEG | 25 |  | Pain fills the [target]'s face as his left ankle shatters from the icy blast. | ankle shatters from the icy blast |
| LEFT LEG | 30 |  | What was once the [target]'s left leg shatters with your well placed strike! | leg shatters with your well placed strike |
| LEFT LEG | 40 |  | A freezing and accurate strike renders the [target]'s left leg a fond memory! | A freezing and accurate strike renders |
| LEFT LEG | 45 |  | Frigid blast shatters the [target]'s left leg beyond all recognition! | leg beyond all recognition |

## Electric  (148 messages, 31 fatal)

| sec | rank | F | message | current match |
|---|---|---|---|---|
| HEAD | 0 |  | Hair stands on end. Neat effect. | Hair stands on end |
| HEAD | 5 |  | Light shock to head. That stings! | Light shock to head |
| HEAD | 15 |  | Shocking jolt to forehead. Painful. | Shocking jolt to forehead |
| HEAD | 15 |  | Nasty shock to the head. The [target] looks dazed and confused. | looks dazed and confused |
| HEAD | 20 |  | Painfully bright jolt to head leaves ears glowing. | Painfully bright jolt to head leaves ears glowing |
| HEAD | 25 |  | Horrid jolt to forehead amplifies brain waves. You hear the [target] scream in your head. | scream in your head |
| HEAD | 30 | F | Horrifying jolt to forehead. Brain explodes in a stunning display of light! | Brain explodes in a stunning display of light |
| HEAD | 35 | F | Spectacular arc of electricity enters one ear and comes out the other. Instant death. | Spectacular arc of electricity enters one ear and comes out the other |
| HEAD | 40 | F | Massive electrical shock turns head into shark bait. Time to feed the fish. | Massive electrical shock turns head into shark bait |
| HEAD | 50 | F | Horrifying electrical shock converts head into blood-stained glass. Death is a step up. | Horrifying electrical shock converts head into blood-stained glass |
| NECK | 0 |  | Tiny sparks around neck. Pretty. | Tiny sparks around neck |
| NECK | 2 |  | Light shock to neck. That stings! | Light shock to neck |
| NECK | 5 |  | Shocking jolt to neck. Painful. | Shocking jolt to neck |
| NECK | 10 |  | Nasty shock to the neck. Gonna be stiff for awhile. | Gonna be stiff for awhile |
| NECK | 12 |  | Painfully bright jolt to neck explodes surrounding skin. Nasty! | Painfully bright jolt to neck explodes surrounding skin |
| NECK | 15 |  | Horrid jolt to neck explodes vocal cords. The [target] gurgles in response. | gurgles in response |
| NECK | 20 | F | Terrible shock to neck fuses larynx shut. A painful death follows. | A painful death follows |
| NECK | 25 | F | Explosive bolt of electricity vaporized neck. Head drops to shoulders then on ground. Never knew what hit 'em. | Explosive bolt of electricity vaporized neck |
| NECK | 30 | F | Arcing bolt of electricity snaps through neck as if it wasn't there and now it really isn't. Instant Death. | as if it wasn't there and now it really isn't |
| NECK | 40 | F | Surprisingly large electrical arc destroys neck and moves up around head making a flashy halo. Rather classical death occurs. | Rather classical death occurs |
| RIGHT EYE | 0 |  | Tiny sparks around right eye.  The [target] blinks in surprise. | Tiny sparks around |
| RIGHT EYE | 1 |  | Light shock to right eye. Bet that stung. |  |
| RIGHT EYE | 3 |  | Heavy spark to right eye causes tears and redness. | eye causes tears and redness |
| RIGHT EYE | 5 |  | Nasty jolt to right eye causes eyelid to split. Gross! | eye causes eyelid to split |
| RIGHT EYE | 10 |  | Heavy shock to right eye bursts a few blood vessels. Sick. | eye bursts a few blood vessels |
| RIGHT EYE | 20 |  | Heavy jolt to right eye chars the optic nerve. Now that's pain! | eye chars the optic nerve |
| RIGHT EYE | 30 | F | Great bolt of electricity pierces right eye and fries brain till dead. | Great bolt of electricity pierces |
| RIGHT EYE | 40 | F | Right eye socket explodes in a dazzling array of multi-colored sparks. Shocking death. | eye socket explodes in a dazzling array of multi-colored sparks |
| RIGHT EYE | 45 | F | Sudden blast of electricity sends right eye flying to the ground! Death from shock results. | Sudden blast of electricity sends |
| RIGHT EYE | 50 | F | Immense electrical bolt finds right eye the perfect conductor to ground out in. A shocking death indeed. | eye the perfect conductor to ground out |
| LEFT EYE | 0 |  | Tiny sparks around left eye.  The [target] blinks in surprise. | Tiny sparks around |
| LEFT EYE | 1 |  | Light shock to left eye. Bet that stung. |  |
| LEFT EYE | 3 |  | Heavy spark to left eye causes tears and redness. | eye causes tears and redness |
| LEFT EYE | 5 |  | Nasty jolt to left eye causes eyelid to split. Gross! | eye causes eyelid to split |
| LEFT EYE | 10 |  | Heavy shock to left eye bursts a few blood vessels. Sick. | eye bursts a few blood vessels |
| LEFT EYE | 20 |  | Heavy jolt to left eye severs optic nerve. Now that's pain! | eye severs optic nerve |
| LEFT EYE | 30 | F | Great bolt of electricity pierces left eye and fries brain till dead. | Great bolt of electricity pierces left eye and fries brain till dead |
| LEFT EYE | 40 | F | Left eye socket explodes in a dazzling array of multi-colored sparks. Shocking death. | eye socket explodes in a dazzling array of multi-colored sparks |
| LEFT EYE | 45 | F | Sudden blast of electricity sends left eye flying to the ground! Death from shock results. | Sudden blast of electricity sends |
| LEFT EYE | 50 | F | Immense electrical bolt finds left eye the perfect conductor to ground out in. A shocking death indeed. | eye the perfect conductor to ground out |
| CHEST | 0 |  | Tiny sparks around chest. Almost tickles. | Tiny sparks around chest |
| CHEST | 5 |  | Light shock to chest. That stings! | Light shock to chest |
| CHEST | 10 |  | Heavy spark to chest. Bet that hurts. | Heavy spark to chest |
| CHEST | 15 |  | Heavy shock to chest illuminates ribcage. Cool! | Heavy shock to chest illuminates ribcage |
| CHEST | 20 |  | Nasty jolt to chest causes heart to skip a beat! | Nasty jolt to chest causes heart to skip a beat |
| CHEST | 25 |  | Heavy jolt to chest causes solar plexus to explode. Remarkable display of spraying blood. | Remarkable display of spraying blood |
| CHEST | 30 |  | Horrid jolt of electricity shatters ribs in a sickening flash of light! | Horrid jolt of electricity shatters ribs in a sickening flash of light |
| CHEST | 50 |  | Massive electrical shock to chest tears through muscle tissue. | Massive electrical shock to chest tears through muscle tissue |
| CHEST | 60 |  | Horrifying jolt of electricity fries chest to a crisp. Toasty! | Horrifying jolt of electricity fries chest to a crisp |
| CHEST | 70 | F | Horrifying bolt of electricity turns chest into a smoking pulp of flesh. No life left there. | Horrifying bolt of electricity turns chest into a smoking pulp of flesh |
| ABDOMEN | 0 |  | Tiny sparks dance around belly. Cool! | Tiny sparks dance around belly |
| ABDOMEN | 5 |  | Light shock to abdomen. That stings! | Light shock to abdomen |
| ABDOMEN | 10 |  | Heavy spark to abdomen. Bet that hurts. | Heavy spark to abdomen |
| ABDOMEN | 15 |  | Heavy shock to abdomen blackens skin. Ick. | Heavy shock to abdomen blackens skin |
| ABDOMEN | 20 |  | Nasty jolt to abdomen makes a [target]'s stomach turn. Urp. | stomach turn |
| ABDOMEN | 25 |  | Heavy jolt to abdomen causes skin to break open exposing liver. Yuck! | Heavy jolt to abdomen causes skin to break open exposing liver |
| ABDOMEN | 30 |  | Horrid jolt of electricity illuminates kidneys! | Horrid jolt of electricity illuminates kidneys |
| ABDOMEN | 50 |  | Massive electrical shock to abdomen turns muscle tissue into a crispy bubbled mess. Not pretty. | Massive electrical shock to abdomen turns muscle tissue into a crispy bubbled mess |
| ABDOMEN | 60 | F | Horrifying jolt of electricity fries abdomen to a crisp. Upper torso falls to the ground. Talk about repugnant! | Horrifying jolt of electricity fries abdomen to a crisp |
| ABDOMEN | 70 | F | Horrifying bolt of electricity crystalizes abdominal area. Spiffy but unfortunately also quite deadly. | Horrifying bolt of electricity crystalizes abdominal area |
| BACK | 0 |  | Static discharge to back. Doesn't hurt, much. | Static discharge to back |
| BACK | 5 |  | Light shock to back. That stings! | Light shock to back |
| BACK | 10 |  | Heavy spark to back. Bet that hurts. | Heavy spark to back |
| BACK | 15 |  | Arcing strand of electricity jolts across a [target]'s back. Pretty. | Arcing strand of electricity jolts across |
| BACK | 20 |  | Nasty jolt to back fuses a few vertebrae. Definitely uncomfortable. | Definitely uncomfortable |
| BACK | 25 |  | Heavy jolt to back shoots up spine. Sympathetic pains almost as bad. | Sympathetic pains almost as bad |
| BACK | 30 |  | Horrid jolt of electricity smokes a shoulder blade! | Horrid jolt of electricity smokes a shoulder blade |
| BACK | 50 |  | Massive electrical shock to back. Won't be bending over for awhile. | Won't be bending over for awhile |
| BACK | 60 | F | Terrifying electrical arc destroys spinal column one vertebra at a time! | Terrifying electrical arc destroys spinal column one vertebra at a time |
| BACK | 70 | F | Massive electrical bolt burns a hole through the back and kidneys. | Massive electrical bolt burns a hole through the back and kidneys |
| RIGHT ARM | 0 |  | Static discharge to right arm. Almost tickles. | Static discharge |
| RIGHT ARM | 3 |  | Light shock to right arm. That stings! |  |
| RIGHT ARM | 7 |  | Heavy spark to right arm. Gonna hurt tomorrow. | Gonna hurt tomorrow |
| RIGHT ARM | 8 |  | Visible wisps of electricity shoot up right arm. Youch! | Visible wisps of electricity shoot up |
| RIGHT ARM | 10 |  | Heavy shock to right arm numbs elbow. | arm numbs elbow |
| RIGHT ARM | 15 |  | Nasty shock to right arm stiffens joints. Nice and painful. | arm stiffens joints |
| RIGHT ARM | 20 |  | Stunning arc of electricity fuses right arm at elbow. | Stunning arc of electricity fuses right arm at elbow |
| RIGHT ARM | 25 |  | Massive electrical shock to the right arm destroys flesh. What remains is useless. | Massive electrical shock |
| RIGHT ARM | 35 |  | Arcing bolt of electricity galvanizes right arm to elbow. Won't be using it for awhile. | Arcing bolt of electricity galvanizes |
| RIGHT ARM | 40 |  | Hideously bright electrical bolt sends right arm into another universe. Happy traveling. | Hideously bright electrical bolt sends |
| LEFT ARM | 0 |  | Static discharge to left arm. Almost tickles. | Static discharge |
| LEFT ARM | 3 |  | Light shock to left arm. That stings! |  |
| LEFT ARM | 7 |  | Heavy spark to left arm. Gonna hurt tomorrow. | Gonna hurt tomorrow |
| LEFT ARM | 8 |  | Visible wisps of electricity shoot up left arm. Youch! | Visible wisps of electricity shoot up |
| LEFT ARM | 10 |  | Heavy shock to left arm numbs elbow. | arm numbs elbow |
| LEFT ARM | 15 |  | Nasty shock to left arm stiffens joints. Nice and painful. | arm stiffens joints |
| LEFT ARM | 20 |  | Stunning arc of electricity fuses left arm at elbow. | Stunning arc of electricity fuses left arm at elbow |
| LEFT ARM | 25 |  | Massive electrical shock to the left arm destroys flesh. What remains is useless. | Massive electrical shock |
| LEFT ARM | 35 |  | Arcing bolt of electricity galvanizes left arm to elbow. Won't be using it for awhile. | Arcing bolt of electricity galvanizes |
| LEFT ARM | 40 |  | Hideously bright electrical bolt sends left arm into another universe. Happy traveling. | Hideously bright electrical bolt sends |
| RIGHT HAND | 0 |  | Static discharge to right hand. Kinda tickles. | Static discharge |
| RIGHT HAND | 1 |  | Light shock to right hand. Fingers tingle. | Fingers tingle |
| RIGHT HAND | 3 |  | Heavy spark to right hand. Bet that hurts. |  |
| RIGHT HAND | 5 |  | Shocking jolt to right hand stiffens skin around knuckles. | stiffens skin around |
| RIGHT HAND | 7 |  | Heavy shock to right hand. Fingers go numb. | Fingers go numb |
| RIGHT HAND | 8 |  | Nasty shock to right hand stiffens fingers. Nice and painful. | hand stiffens fingers |
| RIGHT HAND | 10 |  | Stunning arc of electricity fuses right hand at wrist. | Stunning arc of electricity fuses right hand at wrist |
| RIGHT HAND | 15 |  | Massive electrical shock to the right hand destroys flesh. What remains is useless. | Massive electrical shock |
| RIGHT HAND | 25 |  | Arcing bolt of electricity galvanizes right hand to elbow.  Won't be using it for awhile. | Arcing bolt of electricity galvanizes right hand to elbow.  Won't be using it for awhile |
| RIGHT HAND | 30 |  | Hideously bright electrical bolt sends right hand into another universe. Happy traveling. | Hideously bright electrical bolt sends |
| LEFT HAND | 0 |  | Static discharge to left hand. Kinda tickles. | Static discharge |
| LEFT HAND | 1 |  | Light shock to left hand. Fingers tingle. | Fingers tingle |
| LEFT HAND | 3 |  | Heavy spark to left hand. Bet that hurts. |  |
| LEFT HAND | 5 |  | Shocking jolt to left hand stiffens skin around knuckles. | stiffens skin around |
| LEFT HAND | 7 |  | Heavy shock to left hand. Fingers go numb. | Fingers go numb |
| LEFT HAND | 8 |  | Nasty shock to left hand stiffens fingers. Nice and painful. | hand stiffens fingers |
| LEFT HAND | 10 |  | Stunning arc of electricity fuses left hand at wrist. | Stunning arc of electricity fuses left hand at wrist |
| LEFT HAND | 15 |  | Massive electrical shock to the left hand destroys flesh. What remains is useless. | Massive electrical shock |
| LEFT HAND | 25 |  | Arcing bolt of electricity galvanizes left hand to elbow.  Won't be using it for awhile. | Arcing bolt of electricity galvanizes left hand to elbow.  Won't be using it for awhile |
| LEFT HAND | 30 |  | Hideously bright electrical bolt sends left hand into another universe. Happy traveling. | Hideously bright electrical bolt sends |
| RIGHT LEG | 0 |  | Static discharge to right leg. Doesn't hurt, much. | Static discharge |
| RIGHT LEG | 5 |  | Light shock to right leg. That stings! |  |
| RIGHT LEG | 10 |  | Heavy spark to right leg. The [target] cringes in surprise. | cringes in surprise |
| RIGHT LEG | 15 |  | Visible wisps of electricity shoot up right leg. Youch! | Visible wisps of electricity shoot up |
| RIGHT LEG | 17 |  | Heavy shock to right leg. Gonna limp for awhile. | Gonna limp for awhile |
| RIGHT LEG | 20 |  | Nasty shock to right leg stiffens joints. Nice and painful. | leg stiffens joints |
| RIGHT LEG | 25 |  | Stunning arc of electricity fuses right leg at knee. | Stunning arc of electricity fuses right leg at knee |
| RIGHT LEG | 30 |  | Massive electrical shock to the right leg destroys flesh. What remains is useless. | Massive electrical shock |
| RIGHT LEG | 40 |  | Arcing bolt of electricity galvanizes right leg to knee joint. Won't be using it for awhile. | Arcing bolt of electricity galvanizes |
| RIGHT LEG | 45 |  | Hideously bright electrical bolt sends right leg into another universe. Happy traveling. | Hideously bright electrical bolt sends |
| LEFT LEG | 0 |  | Static discharge to left leg. Doesn't hurt, much. | Static discharge |
| LEFT LEG | 5 |  | Light shock to left leg. That stings! |  |
| LEFT LEG | 10 |  | Heavy spark to left leg. The [target] cringes in surprise. | cringes in surprise |
| LEFT LEG | 15 |  | Visible wisps of electricity shoot up left leg. Youch! | Visible wisps of electricity shoot up |
| LEFT LEG | 17 |  | Heavy shock to left leg. Gonna limp for awhile. | Gonna limp for awhile |
| LEFT LEG | 20 |  | Nasty shock to left leg stiffens joints. Nice and painful. | leg stiffens joints |
| LEFT LEG | 25 |  | Stunning arc of electricity fuses left leg at knee. | Stunning arc of electricity fuses left leg at knee |
| LEFT LEG | 30 |  | Massive electrical shock to the left leg destroys flesh. What remains is useless. | Massive electrical shock |
| LEFT LEG | 40 |  | Arcing bolt of electricity galvanizes left leg to knee joint. Won't be using it for awhile. | Arcing bolt of electricity galvanizes |
| LEFT LEG | 45 |  | Hideously bright electrical bolt sends left leg into another universe. Happy traveling. | Hideously bright electrical bolt sends |
| 1st Person Messaging | 5 |  | Mild electric jolt jolts your whole body.  Talk about a nervous twitch. | Mild electric jolt jolts your whole body |
| 1st Person Messaging | 10 |  | Electric shot shoots pain along your back and legs. | Electric shot shoots pain along your back and legs |
| 1st Person Messaging | 15 |  | Hard jolt contracts every muscle in your upper body. | Hard jolt contracts every muscle in your upper body |
| 1st Person Messaging | 20 |  | Heavy shock sends you to the ground with convulsions! | Heavy shock sends you to the ground with convulsions |
| 1st Person Messaging | 30 | F | Electric blast goes right to the heart! You'll miss that steady beat. | You'll miss that steady beat |
| 1st Person Messaging | 50 | F | Electrical shock overloads your nervous system!  Quite fatal. | Electrical shock overloads your nervous system |
| 1st Person Messaging | 50 | F | Powerful blast sends most of you up in smoke! | Powerful blast sends most of you up in smoke |
| 1st Person Messaging | 60 | F | Electric shock causes a strong enough convulsion to snap your neck. | Electric shock causes a strong enough convulsion to snap your neck |
| 1st Person Messaging | 70 | F | Massive shock totally burns out the nervous system.  Nothing works anymore. | Massive shock totally burns out the nervous system.  Nothing works anymore |
| 3rd Person Messaging | 5 |  | Mild electric jolt sends the <target> into spasms. | Mild electric jolt sends the <target> into spasms |
| 3rd Person Messaging | 10 |  | Electric shot gives the <target> a really bad cramp. | Electric shot gives the <target> a really bad cramp |
| 3rd Person Messaging | 15 |  | Hard jolt knocks the <target> back on his heels. | Hard jolt knocks the <target> back on his heels |
| 3rd Person Messaging | 20 |  | Heavy shock gives the <target> fits! | Heavy shock gives the <target> fits |
| 3rd Person Messaging | 30 | F | Electric blast goes right to the heart! Fibrillation can be fun. | Fibrillation can be fun |
| 3rd Person Messaging | 50 | F | Electrical charge toasts foe!  You get a sharp whiff of burning hair. | You get a sharp whiff of burning hair |
| 3rd Person Messaging | 50 | F | Powerful blast reduces the [target] to a smoldering pile of ash! | to a smoldering pile of ash |
| 3rd Person Messaging | 60 | F | Electric shock causes a strong enough convulsion to snap the <target>'s neck. | Electric shock causes a strong enough convulsion to snap the <target>'s neck |
| 3rd Person Messaging | 70 | F | Massive shock totally burns out the nervous system.  Nothing works anymore. | Massive shock totally burns out the nervous system.  Nothing works anymore |

## Impact  (130 messages, 20 fatal)

| sec | rank | F | message | current match |
|---|---|---|---|---|
| HEAD | 0 |  | Blow grazes cheek. | Blow grazes cheek |
| HEAD | 5 |  | Brushing blow to temple. | Brushing blow to temple |
| HEAD | 10 |  | Strike to head breaks cheekbone. | Strike to head breaks cheekbone |
| HEAD | 15 |  | Nice blow to head! The [target] looks dazed! | Nice blow to head |
| HEAD | 20 |  | Good blow to head! | Good blow to head |
| HEAD | 25 | F | Strong shot to head messes up brain fatally. | Strong shot to head messes up brain fatally |
| HEAD | 30 | F | Hard blow to temple scrambles brain! | Hard blow to temple scrambles brain |
| HEAD | 35 | F | Massive blow to temple drops the [target] in his tracks! | Massive blow to temple drops |
| HEAD | 45 | F | Strike to temple cracks skull open! | Strike to temple cracks skull open |
| HEAD | 50 | F | Blow to head removes skull! | Blow to head removes skull |
| NECK | 0 |  | Blow just brushes neck. | Blow just brushes neck |
| NECK | 2 |  | Blow grazes neck lightly. | Blow grazes neck lightly |
| NECK | 5 |  | Blow to neck tears tissue. | Blow to neck tears tissue |
| NECK | 15 |  | Nice blow to neck! | Nice blow to neck |
| NECK | 12 |  | Good blow to neck! Something snaps! | Something snaps |
| NECK | 15 | F | Strong blow breaks neck! | Strong blow breaks neck |
| NECK | 20 | F | Hard blow to neck loosens head on shoulders. Quite fatal! | Hard blow to neck loosens head on shoulders |
| NECK | 25 | F | Massive blow to neck snaps it! | Massive blow to neck snaps it |
| NECK | 30 | F | Blow shatters bones in the [target]'s neck leaving its head hanging loosely! | neck leaving its head hanging loosely |
| NECK | 40 | F | Strike to the [target]'s throat removes it! | throat removes it |
| RIGHT EYE | 0 |  | Strike catches eyebrow narrowly missing right eye! | Strike catches eyebrow narrowly missing |
| RIGHT EYE | 1 |  | Strike hits close to the right eye! | Strike hits close to the right eye |
| RIGHT EYE | 3 |  | Blow connects right below right eye! | Blow connects right below right eye |
| RIGHT EYE | 5 |  | Glancing blow to right eye scratches cornea! | eye scratches cornea |
| RIGHT EYE | 10 |  | Blow to the eye swells it shut! | Blow to the eye swells it shut |
| RIGHT EYE | 15 |  | Blow to right eye destroys it! | eye destroys it |
| RIGHT EYE | 20 |  | Hard strike to right eye pops it! | Hard strike to right eye pops |
| RIGHT EYE | 40 | F | Massive blow to right eye sending bone back into the brain! | eye sending bone back into the brain |
| RIGHT EYE | 45 | F | Poke to the right eye continues into the brain! | eye continues into the brain |
| RIGHT EYE | 50 | F | Hard strike removes the right eye and a goodly bit of skull! | Hard strike removes the right eye and a goodly bit of skull |
| LEFT EYE | 0 |  | Strike catches eyebrow narrowly missing left eye! | Strike catches eyebrow narrowly missing |
| LEFT EYE | 1 |  | Strike hits close to the left eye! | Strike hits close to the left eye |
| LEFT EYE | 3 |  | Blow connects right below left eye! | Blow connects right below left eye |
| LEFT EYE | 5 |  | Glancing blow to left eye scratches cornea! | eye scratches cornea |
| LEFT EYE | 10 |  | Blow to the eye swells it shut! | Blow to the eye swells it shut |
| LEFT EYE | 15 |  | Blow to left eye destroys it! | eye destroys it |
| LEFT EYE | 20 |  | Hard strike to left eye pops it! | Strike to left eye |
| LEFT EYE | 40 | F | Massive blow to left eye sending bone back into the brain! | eye sending bone back into the brain |
| LEFT EYE | 45 |  | Poke to the left eye continues into the brain! | eye continues into the brain |
| LEFT EYE | 50 | F | Hard strike removes the left eye and a goodly bit of skull! | Hard strike removes |
| CHEST | 0 |  | Strike connects lightly with chest. | Strike connects lightly with chest |
| CHEST | 3 |  | Light strike to chest. | Light strike to chest |
| CHEST | 5 |  | Strike glances off the chest. | Strike glances off the chest |
| CHEST | 15 |  | Nice blow to chest! | Nice blow to chest |
| CHEST | 20 |  | Good blow to chest! | Good blow to chest |
| CHEST | 25 |  | Strong blow to chest! | Strong blow to chest |
| CHEST | 35 |  | Hard blow to chest breaking ribs! Hard to breathe! | Hard blow to chest breaking ribs |
| CHEST | 50 |  | Massive blow to chest collapses sternum! | Massive blow to chest collapses sternum |
| CHEST | 60 |  | Blow to chest frees a rib to spear a lung and heart! | Blow to chest frees a rib to spear a lung and heart |
| CHEST | 70 | F | Strike to chest causes a large gaping hole! | Strike to chest causes a large gaping hole |
| ABDOMEN | 0 |  | Pathetic attack to the abdomen. | Pathetic attack to the abdomen |
| ABDOMEN | 5 |  | Blow connects with abdomen. | Blow connects with abdomen |
| ABDOMEN | 10 |  | Light strike to abdomen. | Light strike to abdomen |
| ABDOMEN | 15 |  | Nice blow to abdomen! | Nice blow to abdomen |
| ABDOMEN | 20 |  | Good blow to the abdomen! | Good blow to the abdomen |
| ABDOMEN | 25 |  | Strong blow to abdomen! | Strong blow to abdomen |
| ABDOMEN | 35 |  | Hard blow to abdomen looks painful! | Hard blow to abdomen looks painful |
| ABDOMEN | 50 |  | Massive blow to abdomen! | Massive blow to abdomen |
| ABDOMEN | 60 | F | Strike to abdomen ruptures internal organs! | Strike to abdomen ruptures internal organs |
| ABDOMEN | 70 | F | Blow to abdomen breaks the [target] almost in two! | almost in two |
| BACK | 0 |  | Strike brushes back. | Strike brushes back |
| BACK | 5 |  | Blow to back connects lightly. | Blow to back connects lightly |
| BACK | 10 |  | Light blow to back. | Light blow to back |
| BACK | 15 |  | Nice blow to back! | Nice blow to back |
| BACK | 20 |  | Good blow to back! | Good blow to back |
| BACK | 15 |  | Strong blow to back! | Strong blow to back |
| BACK | 35 |  | Hard blow to the [target]'s back causes it to cry out in pain! | back causes it to cry out in pain |
| BACK | 50 |  | Massive blow to back separates vertebrae! | Massive blow to back separates vertebrae |
| BACK | 60 | F | Blow to back crushes spinal column. Talk about no backbone! | Talk about no backbone |
| BACK | 70 | F | Blow to back removes the spinal column! | Blow to back removes the spinal column |
| RIGHT ARM | 0 |  | Blow reddens skin on the right arm. | Blow reddens skin |
| RIGHT ARM | 5 |  | Blow grazes right arm lightly. | Blow grazes right arm lightly |
| RIGHT ARM | 7 |  | Light blow to right arm. | Light blow to right arm |
| RIGHT ARM | 8 |  | Nice blow to right arm. | Nice blow to right arm |
| RIGHT ARM | 10 |  | Good blow to right arm! | Good blow to right arm |
| RIGHT ARM | 15 |  | Strong blow to right arm breaks it! | arm breaks it |
| RIGHT ARM | 20 |  | Hard strike to right arm breaking tendons and bone! | arm breaking tendons and bone |
| RIGHT ARM | 25 |  | Massive blow removes the [target]'s right forearm at the elbow! | Massive blow removes |
| RIGHT ARM | 35 |  | Right arm is torn from shoulder! | arm is torn from shoulder |
| RIGHT ARM | 40 |  | Every bone in the right arm shattered and scattered about! | arm shattered and scattered about |
| LEFT ARM | 0 |  | Blow reddens skin on the left arm. | Blow reddens skin |
| LEFT ARM | 5 |  | Blow grazes left arm lightly. | Blow grazes left arm lightly |
| LEFT ARM | 7 |  | Light blow to left arm. | Light blow to left arm |
| LEFT ARM | 8 |  | Nice blow to left arm! | Nice blow to left arm |
| LEFT ARM | 10 |  | Good blow to left arm! | Good blow to left arm |
| LEFT ARM | 15 |  | Strong blow to left arm breaks it! | arm breaks it |
| LEFT ARM | 20 |  | Hard strike to left arm breaking tendons and bone! | arm breaking tendons and bone |
| LEFT ARM | 25 |  | Massive blow removes the [target]'s left forearm at the elbow! | Massive blow removes |
| LEFT ARM | 35 |  | Left arm is torn from shoulder! | arm is torn from shoulder |
| LEFT ARM | 40 |  | Every bone in the left arm shattered and scattered about! | arm shattered and scattered about |
| RIGHT HAND | 0 |  | Fingernail chipped on right hand. | Fingernail chipped |
| RIGHT HAND | 1 |  | Stubs right hand finger. | Stubs right hand finger |
| RIGHT HAND | 3 |  | Brushing blow to right hand. | Brushing blow to right hand |
| RIGHT HAND | 5 |  | Nice blow to right hand! | Nice blow to right hand |
| RIGHT HAND | 7 |  | Good blow to right hand! | Good blow to right hand |
| RIGHT HAND | 8 |  | Strong blow to right hand breaks it! | hand breaks it |
| RIGHT HAND | 10 |  | Hard blow to right hand breaking bones! | hand breaking bones |
| RIGHT HAND | 15 |  | Massive blow to right hand crushing it to pulp! | hand crushing it to pulp |
| RIGHT HAND | 25 |  | Blow removes the [target]'s right hand neatly! | Blow removes |
| RIGHT HAND | 30 |  | Impact removes the right hand in a spray of red mist! | hand in a spray of red mist |
| LEFT HAND | 0 |  | Fingernail chipped on left hand. | Fingernail chipped |
| LEFT HAND | 1 |  | Stubs left hand finger. | Stubs left hand finger |
| LEFT HAND | 3 |  | Brushing blow to left hand. | Brushing blow to left hand |
| LEFT HAND | 5 |  | Nice blow to left hand! | Nice blow to left hand |
| LEFT HAND | 7 |  | Good blow to left hand! | Good blow to left hand |
| LEFT HAND | 8 |  | Strong blow to left hand breaks it! | Strong blow to left hand |
| LEFT HAND | 10 |  | Hard blow to left hand breaking bones! | hand breaking bones |
| LEFT HAND | 15 |  | Massive blow to left hand crushing it to pulp! | hand crushing it to pulp |
| LEFT HAND | 25 |  | Blow removes the [target]'s left hand neatly! | Blow removes |
| LEFT HAND | 30 |  | Impact removes the left hand in a spray of red mist! | hand in a spray of red mist |
| RIGHT LEG | 0 |  | Blow bounces off the right leg. | Blow bounces off |
| RIGHT LEG | 7 |  | Blow grazes right leg. | Blow grazes right leg |
| RIGHT LEG | 10 |  | Light blow to right leg. | Light blow to right leg |
| RIGHT LEG | 15 |  | Nice blow to right leg! | Nice blow to right leg |
| RIGHT LEG | 17 |  | Good blow to right leg! | Good blow to right leg |
| RIGHT LEG | 20 |  | Strong blow to right leg breaks it! | leg breaks it |
| RIGHT LEG | 25 |  | Hard strike to right leg breaking tendons and bone! | leg breaking tendons and bone |
| RIGHT LEG | 30 |  | Massive blow removes the [target]'s right foot! | Massive blow removes |
| RIGHT LEG | 40 |  | Blow to leg severs the Achilles tendon along with the rest of the leg! | Blow to leg severs the Achilles tendon along with the rest of the leg |
| RIGHT LEG | 45 |  | Right leg collapses as the bones turn to dust! | leg collapses as the bones turn to dust |
| LEFT LEG | 0 |  | Blow bounces off the left leg. | Blow bounces off |
| LEFT LEG | 7 |  | Blow grazes left leg. | Blow grazes left leg |
| LEFT LEG | 10 |  | Light blow to left leg. | Light blow to left leg |
| LEFT LEG | 15 |  | Nice blow to left leg! | Nice blow to left leg |
| LEFT LEG | 17 |  | Good blow to left leg! | Good blow to left leg |
| LEFT LEG | 20 |  | Strong blow to left leg breaks it! | leg breaks it |
| LEFT LEG | 25 |  | Hard strike to left leg breaking tendons and bone! | leg breaking tendons and bone |
| LEFT LEG | 30 |  | Massive blow removes the [target]'s left foot! | Massive blow removes |
| LEFT LEG | 40 |  | Blow to leg severs the Achilles tendon along with the rest of the leg! | Blow to leg severs the Achilles tendon along with the rest of the leg |
| LEFT LEG | 45 |  | Left leg collapses as the bones turn to dust! | leg collapses as the bones turn to dust |

## Acid  (130 messages, 20 fatal)

| sec | rank | F | message | current match |
|---|---|---|---|---|
| HEAD | 0 |  | Barely touched. Too bad the [target] ducked! | Barely touched |
| HEAD | 5 |  | Acid splatters on the [target]'s cheek leaving a bright red burn! | cheek leaving a bright red burn |
| HEAD | 10 |  | Acid burn on the right ear! |  |
| HEAD | 15 |  | Burn to cheek.  Not a pretty sight. | Not a pretty sight |
| HEAD | 20 |  | Acid wash cleans the skin off part of the nose and cheek! | Acid wash cleans the skin off part of the nose and cheek |
| HEAD | 25 |  | Right in the face!  Hope the [target] wasn't attached to those facial features! | wasn't attached to those facial features |
| HEAD | 30 | F | Large swig of acid enters mouth.  Swelling cuts off essential breathing! | Swelling cuts off essential breathing |
| HEAD | 35 | F | Acid splash isn't stopped by skull, fries brain! | Acid splash isn't stopped by skull, fries brain |
| HEAD | 40 | F | Acid dissolves the head into a barely recognizable lump! | Acid dissolves the head into a barely recognizable lump |
| HEAD | 50 | F | Blast of acid washes the [target]'s head off clean... and clean off! | Blast of acid washes |
| NECK | 0 |  | Barely touched. Too bad the [target] ducked! | Barely touched |
| NECK | 2 |  | Acid catches the side of the [target]'s neck and drips down in a steaming trail! | neck and drips down in a steaming trail |
| NECK | 5 |  | Acid causes a painful burn on the neck, inflaming the skin! | Acid causes a painful burn on the neck, inflaming the skin |
| NECK | 10 |  | Nasty burn eats the skin away from the spine! | Nasty burn eats the skin away from the spine |
| NECK | 12 |  | Bad burn eats at skin under the chin! | Bad burn eats at skin under the chin |
| NECK | 15 |  | Acid dissolves the skin on the neck exposing the windpipe! | Acid dissolves the skin on the neck exposing the windpipe |
| NECK | 20 | F | Dissolved larynx opens windpipe.  Unfortunately it quickly fills with blood! | Unfortunately it quickly fills with blood |
| NECK | 30 | F | Burn exposes the spine (from the front)! | Burn exposes the spine (from the front) |
| NECK | 35 | F | Acid burns a hole in the neck causing a fatal fluid leak! | Acid burns a hole in the neck causing a fatal fluid leak |
| NECK | 40 | F | Acid bolt removes the neck giving the head no place to go but down! | Acid bolt removes the neck giving the head no place to go but down |
| RIGHT EYE | 0 |  | Soap in the eye would hurt the [target] worse! | Soap in the eye would hurt |
| RIGHT EYE | 1 |  | Drop of acid gets in the [target]'s eye!  Better flush it out. | Better flush it out |
| RIGHT EYE | 5 |  | Acid splash near the eye causes blisters that almost swell it shut! | Acid splash near the eye causes blisters that almost swell it shut |
| RIGHT EYE | 10 |  | Acid gets in eye.  An unscheduled flush! | An unscheduled flush |
| RIGHT EYE | 15 |  | A gob of acid blinds the [target] in the right eye! | A gob of acid blinds |
| RIGHT EYE | 20 |  | Hit to eye empties the socket.  How can something missing be so painful? | How can something missing be so painful |
| RIGHT EYE | 30 | F | Acid hits the [target] full in the eye!  Nothing left but a smoking socket! | but a smoking socket |
| RIGHT EYE | 40 | F | Acid burns right through the [target]'s right eye and into the brain! | eye and into the brain |
| RIGHT EYE | 45 | F | A blast of acid leaves a gaping hole where the [target]'s eye used to be! | A blast of acid leaves a gaping hole where |
| RIGHT EYE | 50 | F | Acid Flush!  The [target]'s brains get washed right out the mouth! | brains get washed |
| LEFT EYE | 0 |  | Soap in the eye would hurt the [target] worse! | Soap in the eye would hurt |
| LEFT EYE | 1 |  | Drop of acid gets in the [target]'s eye!  Better flush it out. | Better flush it out |
| LEFT EYE | 5 |  | Acid splash near the eye causes blisters that almost swell it shut! | Acid splash near the eye causes blisters that almost swell it shut |
| LEFT EYE | 10 |  | Acid gets in eye.  An unscheduled flush! | An unscheduled flush |
| LEFT EYE | 15 |  | A gob of acid blinds the [target] in the left eye! | A gob of acid blinds |
| LEFT EYE | 20 |  | Hit to eye empties the socket.  How can something missing be so painful? | How can something missing be so painful |
| LEFT EYE | 30 | F | Acid hits the [target] full in the eye!  Nothing left but a smoking socket! | but a smoking socket |
| LEFT EYE | 40 | F | Acid turns the [target]'s left eye to mush, and then erodes the brain! | eye to mush, and then erodes the brain |
| LEFT EYE | 45 | F | A blast of acid bores right through eyesocket and into the brain! | through eyesocket and into the brain |
| LEFT EYE | 50 | F | Acid Flush!  The [target]'s brains get washed right out the mouth! | brains get washed |
| CHEST | 0 |  | Acid splattered on the [target]'s chest!  Might leave a stain! | Might leave a stain |
| CHEST | 5 |  | Splash to chest runs off before it does worse than blister the skin. | Splash to chest runs off before it does worse than blister the skin |
| CHEST | 10 |  | Acid reaches the chest causing a nasty rash! | Acid reaches the chest causing a nasty rash |
| CHEST | 15 |  | Spray of acid bites deep into the skin over the sternum. | Spray of acid bites deep into the skin over the sternum |
| CHEST | 20 |  | Acid spray dissolves flesh exposing the muscles over the ribs! | Acid spray dissolves flesh exposing the muscles over the ribs |
| CHEST | 25 |  | Severe burn to the side of the [target]'s chest exposes ribs! | Severe burn to the side |
| CHEST | 30 |  | Acid dissolves connecting cartilage, freeing the [target]'s ribs to move independently. | Acid dissolves connecting cartilage, freeing |
| CHEST | 50 |  | Acid hole in the ribs makes it hard to breathe.  Better get that checked! | Acid hole in the ribs makes it hard to breathe |
| CHEST | 60 | F | Acid eats into lungs.  Hemorrhaging fills the [target]'s lungs with fluid! | Hemorrhaging fills |
| CHEST | 70 | F | Acid bath empties chest.  It's a lot cleaner now. | Acid bath empties chest |
| ABDOMEN | 0 |  | Stung just enough to annoy! | Stung just enough to annoy |
| ABDOMEN | 5 |  | Splash of acid catches hip, leaving a painful trail of smoke. | Splash of acid catches hip, leaving a painful trail of smoke |
| ABDOMEN | 10 |  | Acid burns to the midsection leave a lasting impression. | Acid burns to the midsection leave a lasting impression |
| ABDOMEN | 15 |  | Spray of acid eats into the right hip! | Spray of acid eats |
| ABDOMEN | 20 |  | Bad burn chars the skin.  Weakened abdomen bulges ominously! | Weakened abdomen bulges ominously |
| ABDOMEN | 25 |  | Acid dissolves abdominal muscles.  No sucking in the gut now! | Acid dissolves abdominal muscles.  No sucking in the gut now |
| ABDOMEN | 30 |  | Acid opens midsection.  Loose organs cause the [target] to watch its step! | Acid opens midsection |
| ABDOMEN | 50 |  | Acid burns a hole through the left hip causing severe bleeding! | hip causing severe bleeding |
| ABDOMEN | 60 | F | Acid dissolves the outside of the stomach.  Now that's fire in the belly! | Acid dissolves the outside of the stomach |
| ABDOMEN | 70 | F | Acid eats away the [target]'s midsection.  Not a lot left. | Acid eats away |
| BACK | 0 |  | The [target] gets splattered with a little acid.  Big deal! | gets splattered with a little acid |
| BACK | 5 |  | Splash of acid hits shoulder and runs down the back in a painful trail. | Splash of acid hits shoulder and runs down the back in a painful trail |
| BACK | 10 |  | Acid works its way into the skin.  Nasty burn. | Acid works its way into the skin.  Nasty burn |
| BACK | 15 |  | Spray of caustic liquid burns the skin along the back! | Spray of caustic liquid burns the skin along the back |
| BACK | 20 |  | Hit eats into the back dissolving part of a shoulder blade! | Hit eats into the back dissolving part of a shoulder blade |
| BACK | 25 |  | Spray of acid exposes the spine! | Spray of acid exposes the spine |
| BACK | 30 |  | Acid causes some lower back troubles.  Large holes do that. | Acid causes some lower back troubles |
| BACK | 50 |  | Acid causing a gaping hole in the back can't be healthy! | Acid causing a gaping hole in the back can't be healthy |
| BACK | 60 |  | Large spot of acid dissolves the [target]'s kidneys. | Large spot of acid dissolves |
| BACK | 70 |  | Acid eats away the [target]'s spine and most of what's under it. | spine and most of what's under it |
| RIGHT ARM | 0 |  | Splash to the arm hardly touches the [target]. | Splash to the arm hardly touches |
| RIGHT ARM | 3 |  | The [target] avoids the worst of the attack but still gets a singed forearm. | avoids the worst of the attack but still gets a singed forearm |
| RIGHT ARM | 7 |  | Acid gets on the right arm raising some large blisters. | arm raising some large blisters |
| RIGHT ARM | 8 |  | Acid raises angry red welts on the arm! | Acid raises angry red welts on the arm |
| RIGHT ARM | 10 |  | Hit on the arm chars the skin and eats into the underlying muscles! | Hit on the arm chars the skin and eats into the underlying muscles |
| RIGHT ARM | 15 |  | Burn to the elbow eats through tendons.  Muscles snap free! | Burn to the elbow eats through tendons |
| RIGHT ARM | 20 |  | Acid dissolves the elbow ligaments.  Arm swings in a very odd manner! | Acid dissolves the elbow ligaments |
| RIGHT ARM | 25 |  | The [target]'s arm is drenched in acid!  Flesh and bones are reduced to a smoking slime! | Flesh and bones are reduced to a smoking slime |
| RIGHT ARM | 35 |  | Spray of acid reduces the forearm to gelatin. | Spray of acid reduces the forearm to gelatin |
| RIGHT ARM | 40 |  | Acid strikes the arm leaving nothing but a puddle of melted flesh! | Acid strikes the arm leaving nothing but a puddle of melted flesh |
| LEFT ARM | 0 |  | Splash to the arm hardly touches the [target]. | Splash to the arm hardly touches |
| LEFT ARM | 3 |  | The [target] avoids the worst of the attack but still gets a singed forearm. | avoids the worst of the attack but still gets a singed forearm |
| LEFT ARM | 7 |  | Acid gets on the left arm raising some large blisters. | arm raising some large blisters |
| LEFT ARM | 8 |  | Acid raises angry red welts on the arm! | Acid raises angry red welts on the arm |
| LEFT ARM | 10 |  | Hit on the arm chars the skin and eats into the underlying muscles! | Hit on the arm chars the skin and eats into the underlying muscles |
| LEFT ARM | 15 |  | Burn to the elbow eats through tendons.  Muscles snap free! | Burn to the elbow eats through tendons |
| LEFT ARM | 20 |  | Acid dissolves the elbow ligaments.  Arm swings in a very odd manner! | Acid dissolves the elbow ligaments |
| LEFT ARM | 25 |  | The [target]'s arm is drenched in acid!  Flesh and bones are reduced to a smoking slime! | Flesh and bones are reduced to a smoking slime |
| LEFT ARM | 35 |  | Spray of acid reduces the forearm to gelatin. | Spray of acid reduces the forearm to gelatin |
| LEFT ARM | 40 |  | Acid strikes the arm leaving nothing but a puddle of melted flesh! | Acid strikes the arm leaving nothing but a puddle of melted flesh |
| RIGHT HAND | 0 |  | Splash to the hand hardly touches the [target]. | Splash to the hand hardly touches |
| RIGHT HAND | 1 |  | Spray just catches the hand as the little finger is badly blistered. | Spray just catches the hand as the little finger is badly blistered |
| RIGHT HAND | 3 |  | Acid gets on the right hand raising some large blisters. | hand raising some large blisters |
| RIGHT HAND | 5 |  | Splash to the back of the hand causes the skin to smoke! | Splash to the back of the hand causes the skin to smoke |
| RIGHT HAND | 7 |  | Spray eats through the skin on the hand and dissolves some ligaments! | Spray eats through the skin on the hand and dissolves some ligaments |
| RIGHT HAND | 8 |  | Excruciating pain as back of hand is dissolved! | Excruciating pain as back of hand is dissolved |
| RIGHT HAND | 10 |  | Severe burn removes several fingers and formerly good parts of the hand! | Severe burn removes several fingers and formerly good parts of the hand |
| RIGHT HAND | 15 |  | Acid dissolves the [target]'s right hand leaving only smoldering ruin! | hand leaving only smoldering ruin |
| RIGHT HAND | 25 |  | Acid eats the hand off cleanly leaving only the stump. | Acid eats the hand off cleanly leaving only the stump |
| RIGHT HAND | 30 |  | Acid very slowly eats off hand. | Acid very slowly eats off hand |
| LEFT HAND | 0 |  | Splash to the hand hardly touches the [target]. | Splash to the hand hardly touches |
| LEFT HAND | 1 |  | Spray just catches the hand as the little finger is badly blistered. | Spray just catches the hand as the little finger is badly blistered |
| LEFT HAND | 3 |  | Acid gets on the left hand raising some large blisters. | hand raising some large blisters |
| LEFT HAND | 5 |  | Splash to the back of the hand causes the skin to smoke! | Splash to the back of the hand causes the skin to smoke |
| LEFT HAND | 7 |  | Spray eats through the skin on the hand and dissolves some ligaments! | Spray eats through the skin on the hand and dissolves some ligaments |
| LEFT HAND | 8 |  | Excruciating pain as back of hand is dissolved! | Excruciating pain as back of hand is dissolved |
| LEFT HAND | 10 |  | Severe burn removes several fingers and formerly good parts of the hand! | Severe burn removes several fingers and formerly good parts of the hand |
| LEFT HAND | 15 |  | Acid dissolves the [target]'s left hand leaving only smoldering ruin! | hand leaving only smoldering ruin |
| LEFT HAND | 25 |  | Acid eats the hand off cleanly leaving only the stump. | Acid eats the hand off cleanly leaving only the stump |
| LEFT HAND | 30 |  | Acid very slowly eats off hand. | Acid very slowly eats off hand |
| RIGHT LEG | 0 |  | Splash to the leg hardly touches the [target]. | Splash to the leg hardly touches |
| RIGHT LEG | 5 |  | Bit of acid strikes the [target]'s calf leaving bright red spots. | calf leaving bright red spots |
| RIGHT LEG | 10 |  | Acid gets on the right leg raising some large blisters. | leg raising some large blisters |
| RIGHT LEG | 15 |  | Acid raises angry red welts on the leg! | Acid raises angry red welts on the leg |
| RIGHT LEG | 17 |  | Hit on the leg chars the skin and eats into the underlying muscles! | Hit on the leg chars the skin and eats into the underlying muscles |
| RIGHT LEG | 20 |  | Strike dissolves the tendons in the ankle, effectively severing foot! | Strike dissolves the tendons in the ankle, effectively severing foot |
| RIGHT LEG | 25 |  | Acid dissolves the knee ligaments. The [target]'s tibia passes its femur in a very unpleasant manner! | tibia passes its femur in a very unpleasant manner |
| RIGHT LEG | 30 |  | The [target] screams! The [target]'s right leg is reduced to a puddle of bubbling slime! | leg is reduced to a puddle of bubbling slime |
| RIGHT LEG | 40 |  | Acid hits leg squarely leaving nothing useful behind. | Acid hits leg squarely leaving nothing useful behind |
| RIGHT LEG | 45 |  | Acid to the foot forms a pool into which the [target] quickly melts to the hip! | Acid to the foot forms a pool into which |
| LEFT LEG | 0 |  | Splash to the leg hardly touches the [target]. | Splash to the leg hardly touches |
| LEFT LEG | 5 |  | Bit of acid strikes the [target]'s calf leaving bright red spots. | calf leaving bright red spots |
| LEFT LEG | 10 |  | Acid gets on the left leg raising some large blisters. | leg raising some large blisters |
| LEFT LEG | 15 |  | Acid raises angry red welts on the leg! | Acid raises angry red welts on the leg |
| LEFT LEG | 17 |  | Hit on the leg chars the skin and eats into the underlying muscles! | Hit on the leg chars the skin and eats into the underlying muscles |
| LEFT LEG | 20 |  | Strike dissolves the tendons in the ankle, effectively severing foot! | Strike dissolves the tendons in the ankle, effectively severing foot |
| LEFT LEG | 25 |  | Acid dissolves the knee ligaments. The [target]'s tibia passes its femur in a very unpleasant manner! | tibia passes its femur in a very unpleasant manner |
| LEFT LEG | 30 |  | The [target] screams! The [target]'s left leg is reduced to a puddle of bubbling slime! | leg is reduced to a puddle of bubbling slime |
| LEFT LEG | 40 |  | Acid hits leg squarely leaving nothing useful behind. | Acid hits leg squarely leaving nothing useful behind |
| LEFT LEG | 45 |  | Acid to the foot forms a pool into which the [target] quickly melts to the hip! | Acid to the foot forms a pool into which |

## Crush  (130 messages, 21 fatal)

| sec | rank | F | message | current match |
|---|---|---|---|---|
| HEAD | 0 |  | Love tap upside the [target]'s head! | Love tap upside the |
| HEAD | 5 |  | Blow to the head causes the [target]'s ears to ring! | Blow to the head causes |
| HEAD | 10 |  | Hearty smack to the head. | Hearty smack to the head |
| HEAD | 15 |  | You broke the [target]'s nose! |  |
| HEAD | 20 |  | Skull cracks in several places. | Skull cracks in several places |
| HEAD | 25 | F | Solid strike caves the [target]'s skull in,resulting in instant death! | skull in,resulting in instant death |
| HEAD | 30 | F | Mighty swing separates head from shoulders. | Mighty swing separates head from shoulders |
| HEAD | 35 | F | Tremendous blow crushes skull like a ripe melon. | Tremendous blow crushes skull like a ripe melon |
| HEAD | 40 | F | Brain driven into neck by mammoth downswing! | Brain driven into neck by mammoth downswing |
| HEAD | 50 | F | Incredible blast shatters head into a red spray. | Incredible blast shatters head into a red spray |
| NECK | 0 |  | You leave a nice bruise on the [target]'s neck! | You leave a nice bruise |
| NECK | 2 |  | Whiplash! |  |
| NECK | 5 |  | Neck vertebrae snap. | Neck vertebrae snap |
| NECK | 10 |  | Shot to the neck scrapes away skin. Some nasty bleeding. | Shot to the neck scrapes away skin |
| NECK | 12 |  | Throat nearly crushed. The [target] makes gurgling noises. | Throat nearly crushed |
| NECK | 15 | F | Neck broken. The [target] twitches several times before dying. | twitches several times before dying |
| NECK | 20 | F | You hear several snaps as the [target]'s neck is broken in several places. | neck is broken in several places |
| NECK | 25 | F | Vertebrae in [target]'s neck disintegrate from impact! Neck sinks into shoulders. | neck disintegrate from impact |
| NECK | 30 | F | Shot to neck sends [target] into shock which leads very quickly to death. | into shock which leads very quickly to death |
| NECK | 40 | F | Neck removed, head falls to the ground. | Neck removed, head falls to the ground |
| RIGHT EYE | 0 |  | Swing at the [target]'s eye catches an eyebrow instead! | eye catches an eyebrow instead |
| RIGHT EYE | 1 |  | Cut over the [target]'s right eye. |  |
| RIGHT EYE | 3 |  | Strike to the eye clips the eyebrow. | Strike to the eye clips the eyebrow |
| RIGHT EYE | 5 |  | Smack to the eye bursts blood vessels. | Smack to the eye bursts blood vessels |
| RIGHT EYE | 10 |  | Crack to the head swells eye shut. | Crack to the head swells eye shut |
| RIGHT EYE | 15 |  | Eye crushed by a hard blow to the face! | Eye crushed by a hard blow to the face |
| RIGHT EYE | 20 |  | Crushing blow to head closes that eye for good. | Crushing blow to head closes that eye for good |
| RIGHT EYE | 40 | F | Blow to eye impacts the brain. [target] twitches violently, then dies. | twitches violently, then dies |
| RIGHT EYE | 45 | F | Right eye ripped from head, along with most of brain. | eye ripped from head, along with most of brain |
| RIGHT EYE | 50 | F | Smash to cheek driving bone through the eye and into the brain. | Smash to cheek driving bone through the eye and into the brain |
| LEFT EYE | 0 |  | Swing at the [target]'s eye catches an eyebrow instead! | eye catches an eyebrow instead |
| LEFT EYE | 1 |  | Cut over the [target]'s left eye. |  |
| LEFT EYE | 3 |  | Strike to the eye clips the eyebrow. | Strike to the eye clips the eyebrow |
| LEFT EYE | 5 |  | Smack to the eye bursts blood vessels. | Smack to the eye bursts blood vessels |
| LEFT EYE | 10 |  | Crack to the head swells eye shut. | Crack to the head swells eye shut |
| LEFT EYE | 15 |  | Eye crushed by a hard blow to the face! | Eye crushed by a hard blow to the face |
| LEFT EYE | 20 |  | Crushing blow to head closes that eye for good. | Crushing blow to head closes that eye for good |
| LEFT EYE | 40 | F | Blow to eye impacts the brain. [target] twitches violently,then dies. | Blow to eye impacts the brain |
| LEFT EYE | 45 | F | Left eye ripped from head, along with most of brain. | eye ripped from head, along with most of brain |
| LEFT EYE | 50 | F | Smash to cheek driving bone through the eye and into the brain. | Smash to cheek driving bone through the eye and into the brain |
| CHEST | 0 |  | Thumped the [target]'s chest. |  |
| CHEST | 5 |  | Blow leaves an imprint on the [target]'s chest! | Blow leaves an imprint |
| CHEST | 10 |  | Mighty blow cracks several ribs. | Mighty blow cracks several ribs |
| CHEST | 15 |  | Blow to chest causes the [target]'s heart to skip a beat. | heart to skip a beat |
| CHEST | 20 |  | Whoosh! Several ribs driven into lungs. | Several ribs driven into lungs |
| CHEST | 25 |  | Whoosh! Several ribs driven into lungs. | Several ribs driven into lungs |
| CHEST | 45 |  | Awesome shot collapses a lung! | Awesome shot collapses a lung |
| CHEST | 60 |  | Blow cracks a rib and punctures a lung. Breathing becomes a challenge. | Blow cracks a rib and punctures a lung |
| CHEST | 65 |  | Massive blow punches a hole through the [target]'s chest! | Massive blow punches a hole |
| CHEST | 70 | F | Massive blow smashes through ribs and drives [target]'s heart out the back. | heart out the back |
| ABDOMEN | 0 |  | Hit glances off the [target]'s hip. | Hit glances off |
| ABDOMEN | 5 |  | Stomach shot lands with a hollow *thump*. | Stomach shot lands with a hollow *thump* |
| ABDOMEN | 10 |  | Grazing blow to the stomach. | Grazing blow to the stomach |
| ABDOMEN | 15 |  | Internal organs bruised. | Internal organs bruised |
| ABDOMEN | 20 |  | Stomach ripped open by mighty blow! | Stomach ripped open by mighty blow |
| ABDOMEN | 25 |  | Knocked back several feet by blow to abdomen. | Knocked back several feet by blow to abdomen |
| ABDOMEN | 30 |  | Blow ruptures the stomach! | Blow ruptures the stomach |
| ABDOMEN | 50 |  | Blow to stomach rearranges some organs! | Blow to stomach rearranges some organs |
| ABDOMEN | 60 | F | Incredible smash to what used to be a stomach! | Incredible smash to what used to be a stomach |
| ABDOMEN | 75 | F | A mighty hit turns the [target]'s insides to outsides! | insides to outsides |
| BACK | 0 |  | Blow glances off the [target]'s shoulder. | Blow glances off |
| BACK | 3 |  | Jarring blow to the [target]'s back. | Jarring blow |
| BACK | 10 |  | Blow to back cracks several vertebrae. | Blow to back cracks several vertebrae |
| BACK | 15 |  | Respectable shot to the back. | Respectable shot to the back |
| BACK | 20 |  | Flesh ripped from back, muscles exposed. | Flesh ripped from back, muscles exposed |
| BACK | 25 |  | Knocked sideways several feet by blow to back. | Knocked sideways several feet by blow to back |
| BACK | 30 |  | Spinal cord damaged by smash to the back. | Spinal cord damaged by smash to the back |
| BACK | 50 |  | Crushing blow to the spine! The [target] slumps to the ground. | Crushing blow to the spine |
| BACK | 60 | F | Body pulped to a gooey mass.  Watch where you step! | Body pulped to a gooey mass |
| BACK | 75 | F | A mighty blow cleaves a swath through the [target]'s back, taking the spine with it. | back, taking the spine with it |
| RIGHT ARM | 0 |  | A feeble blow to the [target]'s right arm! | A feeble blow |
| RIGHT ARM | 3 |  | Blow raises a welt on the [target]'s right arm. | Blow raises a welt |
| RIGHT ARM | 7 |  | Bones in right arm crack. | Bones in right arm crack |
| RIGHT ARM | 8 |  | Large gash to the right arm, several muscles torn. | arm, several muscles torn |
| RIGHT ARM | 10 |  | Right elbow smashed into a thousand pieces. | elbow smashed into a thousand pieces |
| RIGHT ARM | 15 |  | Weapon arm mangled horribly. | Weapon arm mangled horribly |
| RIGHT ARM | 20 |  | Hard hit shatters weapon arm. | Hard hit shatters weapon arm |
| RIGHT ARM | 25 |  | Right arm ripped from socket at the elbow! | arm ripped from socket at the elbow |
| RIGHT ARM | 35 |  | Lucky shot rips through bone and muscle sending weapon arm flying. | Lucky shot rips through bone and muscle sending weapon arm flying |
| RIGHT ARM | 40 |  | Weapon arm removed at the shoulder! | Weapon arm removed at the shoulder |
| LEFT ARM | 0 |  | A feeble blow to the [target]'s left arm! | A feeble blow |
| LEFT ARM | 3 |  | Blow raises a welt on the [target]'s left arm. | Blow raises a welt |
| LEFT ARM | 7 |  | Bones in left arm crack. | Bones in left arm crack |
| LEFT ARM | 8 |  | Large gash to the left arm, several muscles torn. | arm, several muscles torn |
| LEFT ARM | 10 |  | Left elbow smashed into a thousand pieces. | elbow smashed into a thousand pieces |
| LEFT ARM | 15 |  | Shield arm mangled horribly. | Shield arm mangled horribly |
| LEFT ARM | 20 |  | Hard hit shatters shield arm. | Hard hit shatters shield arm |
| LEFT ARM | 25 |  | Left arm ripped from socket at the elbow! | arm ripped from socket at the elbow |
| LEFT ARM | 35 |  | Lucky shot rips through bone and muscle sending shield arm flying. | Lucky shot rips through bone and muscle sending shield arm flying |
| LEFT ARM | 40 |  | Shield arm removed at the shoulder! | Shield arm removed at the shoulder |
| RIGHT HAND | 0 |  | Blow nicks the [target]'s right hand. |  |
| RIGHT HAND | 1 |  | Broken finger on the [target]'s right hand! | Broken finger |
| RIGHT HAND | 3 |  | Flattened the [target]'s right hand. | Flattened the |
| RIGHT HAND | 5 |  | Finger ripped away from right hand. | Finger ripped away from right hand |
| RIGHT HAND | 7 |  | Right hand smashed into a pulpy mass. | hand smashed into a pulpy mass |
| RIGHT HAND | 5 |  | Right hand mangled horribly. | hand mangled horribly |
| RIGHT HAND | 10 |  | Blast to hand reduces it to pulp! | Blast to hand reduces it to pulp |
| RIGHT HAND | 15 |  | Blast to hand sends fingers flying in several different directions. | Blast to hand sends fingers flying in several different directions |
| RIGHT HAND | 25 |  | Lucky shot severs right hand and sends it flying. | hand and sends it flying |
| RIGHT HAND | 30 |  | Right hand severed at the wrist! | hand severed at the wrist |
| LEFT HAND | 0 |  | Blow nicks the [target]'s left hand. |  |
| LEFT HAND | 1 |  | Broken finger on the [target]'s left hand! | Broken finger |
| LEFT HAND | 3 |  | Flattened the [target]'s left hand. | Flattened the |
| LEFT HAND | 5 |  | Finger ripped away from left hand. | Finger ripped away from left hand |
| LEFT HAND | 7 |  | Left hand smashed into a pulpy mass. | hand smashed into a pulpy mass |
| LEFT HAND | 8 |  | Left hand mangled horribly. | hand mangled horribly |
| LEFT HAND | 10 |  | Blast to hand reduces it to pulp! | Blast to hand reduces it to pulp |
| LEFT HAND | 15 |  | Blast to hand sends fingers flying in several different directions. | Blast to hand sends fingers flying in several different directions |
| LEFT HAND | 25 |  | Lucky shot severs left hand and sends it flying. | hand and sends it flying |
| LEFT HAND | 30 |  | Left hand severed at the wrist! | hand severed at the wrist |
| RIGHT LEG | 0 |  | Glancing blow to the [target]'s right leg! | Glancing blow |
| RIGHT LEG | 7 |  | Torn muscle in the [target]'s right leg! |  |
| RIGHT LEG | 10 |  | Smash to the kneecap. | Smash to the kneecap |
| RIGHT LEG | 15 |  | You ripped a chunk out of the [target]'s right leg with that one. | You ripped a chunk out |
| RIGHT LEG | 17 |  | Right kneecap smashed into pulp. | kneecap smashed into pulp |
| RIGHT LEG | 20 |  | Right leg mangled horribly. | leg mangled horribly |
| RIGHT LEG | 25 |  | Hard blow breaks the femur! | Hard blow breaks the femur |
| RIGHT LEG | 30 |  | Right leg ripped from socket at the knee! | leg ripped from socket at the knee |
| RIGHT LEG | 40 |  | Lucky shot rips through bone and muscle sending right leg flying. | Lucky shot rips through bone and muscle sending right leg flying |
| RIGHT LEG | 45 |  | Right hip pulped, severing the leg. | hip pulped, severing the leg |
| LEFT LEG | 0 |  | Glancing blow to the [target]'s left leg! | Glancing blow |
| LEFT LEG | 7 |  | Torn muscle in the [target]'s left leg! |  |
| LEFT LEG | 10 |  | Smash to the kneecap. | Smash to the kneecap |
| LEFT LEG | 15 |  | You ripped a chunk out of the [target]'s left leg with that one. | You ripped a chunk out |
| LEFT LEG | 17 |  | Left kneecap smashed into pulp. | kneecap smashed into pulp |
| LEFT LEG | 20 |  | Left leg mangled horribly. | leg mangled horribly |
| LEFT LEG | 25 |  | Hard blow breaks the femur! | Hard blow breaks the femur |
| LEFT LEG | 30 |  | Left leg ripped from socket at the knee! | leg ripped from socket at the knee |
| LEFT LEG | 40 |  | Lucky shot rips through bone and muscle sending left leg flying. | Lucky shot rips through bone and muscle sending left leg flying |
| LEFT LEG | 45 |  | Left hip pulped, severing the leg. | hip pulped, severing the leg |

## Disintegration  (130 messages, 22 fatal)

| sec | rank | F | message | current match |
|---|---|---|---|---|
| HEAD | 0 |  | Weak strike to head. | Weak strike to head |
| HEAD | 5 (3) |  | Poor strike removes hair from head, but little else. | Poor strike removes hair from head, but little else |
| HEAD | 10 (6) |  | Flesh stripped from both cheeks, leaving dimples.  How cute. | Flesh stripped from both cheeks, leaving dimples |
| HEAD | 15 (10) |  | Hair and flesh stripped from side of head! | Hair and flesh stripped from side of head |
| HEAD | 20 (15) |  | Strike to head vaporizes ear! Can you hear me now? | Strike to head vaporizes ear |
| HEAD | 25 (20) |  | Strike to cheek manages to remove the majority of the [target]'s jaw! | Strike to cheek manages to remove the majority |
| HEAD | 30 (25) | F | Blast leaves bloody trench of bone and brains along side of skull! | Blast leaves bloody trench of bone and brains along side of skull |
| HEAD | 35 (30) | F | Front half of head devoured.  Brains are now optional. | Front half of head devoured.  Brains are now optional |
| HEAD | 40 | F | Blast quickly engulfs entire head, leaving only a bleached skull behind. | Blast quickly engulfs entire head, leaving only a bleached skull behind |
| HEAD | 45 (50) | F | Entire head is vaporized in a flash!  Now much shorter, the [target] falls to the ground, dead. | Entire head is vaporized in a flash |
| NECK | 0 |  | Misaimed strike grazes neck. | Misaimed strike grazes neck |
| NECK | 5 (2) |  | A small, but painful slice of neck vanishes! | A small, but painful slice of neck vanishes |
| NECK | 10 (5) |  | Chunks of muscle removed from neck! | Chunks of muscle removed from neck |
| NECK | 15 (10) |  | Side of neck disintegrated, causing the [target]'s head to tilt left. | head to tilt |
| NECK | 20 (12) |  | Raking blast eliminates portions of neck and head! | Raking blast eliminates portions of neck and head |
| NECK | 25 (15) |  | Strike to neck strips away surface, exposing windpipe! | Strike to neck strips away surface, exposing windpipe |
| NECK | 30 (20) | F | Throat disappears!  That'll make breathing difficult. | Throat disappears!  That'll make breathing difficult |
| NECK | 35 (25) | F | Neck melts away, leaving the head dangling from a bit of spinal column in a very undignified manner. | Neck melts away, leaving the head dangling from a bit of spinal column in a very undignified manner |
| NECK | 40 (30) | F | Neck cleanly eliminated, allowing head to drop until it rests on the [target]'s shoulder blades. | Neck cleanly eliminated, allowing head to drop until it rests |
| NECK | 45 (40) | F | Vicious attack begins at base of neck and moves upwards, leaving only a fine mist above the [target]'s shoulders! | Vicious attack begins at base of neck and moves upwards, leaving only a fine mist above |
| RIGHT EYE | 0 |  | Small portions of right eyelid disappear. | eyelid disappear |
| RIGHT EYE | 5 (1) |  | Eyebrow and eyelashes of right eye melted off. | Eyebrow and eyelashes of right eye melted |
| RIGHT EYE | 10 (3) |  | Right eyelid turns to dust, causing the [target] to blink rapidly, or try to. | eyelid turns to dust, causing |
| RIGHT EYE | 15 (5) |  | Portions of eye socket turned to fine powder! | Portions of eye socket turned to fine powder |
| RIGHT EYE | 20 (10) |  | Blast removes sections of eye socket. | Blast removes sections of eye socket |
| RIGHT EYE | 25 (20) |  | Ocular fluid streaks the [target]'s cheek as right eye is reduced to a red, hollow socket! | eye is reduced to a red, hollow socket |
| RIGHT EYE | 30 (25) | F | Frightful blast to the face strips flesh to the bone and removes right eye! | Frightful blast to the face strips flesh to the bone and removes right eye |
| RIGHT EYE | 35 (40) | F | Blast disintegrates right eye and portions of the skull behind! | eye and portions of the skull behind |
| RIGHT EYE | 40 (45) | F | Precise shot vaporizes right eye and much of brain behind while leaving skull intact. | Precise shot vaporizes right eye and much of brain behind while leaving skull intact |
| RIGHT EYE | 50 | F | Right eye and most of skull removed!  What remains is a bloody mess! | Right eye and most of skull removed!  What remains is a bloody mess |
| LEFT EYE | 0 |  | Small portions of left eyelid disappear. | eyelid disappear |
| LEFT EYE | 5 (1) |  | Eyebrow and eyelashes of left eye melted off. | Eyebrow and eyelashes of left eye melted |
| LEFT EYE | 10 (3) |  | Left eyelid turns to dust, causing the [target] to blink rapidly, or try to. | eyelid turns to dust, causing |
| LEFT EYE | 15 (5) |  | Portions of eye socket turned to fine powder! | Portions of eye socket turned to fine powder |
| LEFT EYE | 20 (10) |  | Blast removes sections of eye socket. | Blast removes sections of eye socket |
| LEFT EYE | 25 (20) |  | Ocular fluid streaks the [target]'s cheek as left eye is reduced to a red, hollow socket! | eye is reduced to a red, hollow socket |
| LEFT EYE | 30 (25) | F | Frightful blast to the face strips flesh to the bone and removes left eye! | Frightful blast to the face strips flesh to the bone and removes left eye |
| LEFT EYE | 35 (40) | F | Blast disintegrates left eye and portions of the skull behind! | eye and portions of the skull behind |
| LEFT EYE | 40 (45) | F | Precise shot vaporizes left eye and much of brain behind while leaving skull intact. | Precise shot vaporizes left eye and much of brain behind while leaving skull intact |
| LEFT EYE | 50 | F | Left eye and most of skull removed!  What remains is a bloody mess! | Left eye and most of skull removed!  What remains is a bloody mess |
| CHEST | 0 |  | Light chest strike. | Light chest strike |
| CHEST | 5 |  | Flesh painfully vaporized from side! | Flesh painfully vaporized from side |
| CHEST | 10 (12) |  | Wide segment of skin disappears from chest. | Wide segment of skin disappears from chest |
| CHEST | 15 (20) |  | Groove etched into skin of chest and quickly fills with blood. | Groove etched into skin of chest and quickly fills with blood |
| CHEST | 30 (25) |  | Long, wide strip eliminated from chest, giving blood a much-needed vacation. | Long, wide strip eliminated from chest, giving blood a much-needed vacation |
| CHEST | 35 |  | Deep, penetrating wound etched into chest, exposing ribs and lung tissue! | Deep, penetrating wound etched into chest, exposing ribs and lung tissue |
| CHEST | 40 |  | Deep hole created in chest, removing several useful arteries! Blood gushes wildly! | removing several useful arteries |
| CHEST | 50 |  | Shot blankets chest, leaving a brilliantly bleached but empty ribcage! Most impressive! | Shot blankets chest, leaving a brilliantly bleached but empty ribcage |
| CHEST | 60 | F | Most of chest removed, resulting in gaping hole in midsection! | Most of chest removed, resulting in gaping hole in midsection |
| CHEST | 70 | F | Blast hits chest and expands to envelop entire body!  The [target] is no more! | Blast hits chest and expands to envelop entire body |
| ABDOMEN | 0 |  | Abdomen slightly grazed. | Abdomen slightly grazed |
| ABDOMEN | 5 |  | Blast creates interesting designs on torso, but little damage. | Blast creates interesting designs on torso, but little damage |
| ABDOMEN | 10 (12) |  | Flesh removed, forming a long gash across abdomen! | Flesh removed, forming a long gash across abdomen |
| ABDOMEN | 15 (20) |  | Torso skin and muscle disintegrate rapidly, providing an interior view. So that's what a spleen looks like! | Torso skin and muscle disintegrate rapidly, providing an interior view |
| ABDOMEN | 20 (25) |  | Unlucky strike removes muscles from abdomen, but misses vital organs. | Unlucky strike removes muscles from abdomen, but misses vital organs |
| ABDOMEN | 35 |  | Strong strike turns belly button into more of a belly canyon. | Strong strike turns belly button into more of a belly canyon |
| ABDOMEN | 40 |  | Kidney and covering tissue vaporized!  Hope the [target] has a spare! | Kidney and covering tissue vaporized |
| ABDOMEN | 50 |  | Abdomen gruesomely sliced open, revealing partially disintegrated organs! | Abdomen gruesomely sliced open, revealing partially disintegrated organs |
| ABDOMEN | 60 | F | Vicious blast turns vital organs into fine red powder, leaving the [target] with an empty feeling inside. | Vicious blast turns vital organs into fine red powder, leaving |
| ABDOMEN | 70 | F | Half of midsection reduced to a fine red mist!  Now unsupported, half-vaporized organs topple out onto the ground! What a mess! | Half of midsection reduced to a fine red mist!  Now unsupported, half-vaporized organs topple out onto the ground |
| BACK | 0 |  | Light strike to back. | Light strike to back |
| BACK | 5 |  | Strips of flesh disappear from the [target]'s back. | Strips of flesh disappear |
| BACK | 10 (12) |  | Large patches of skin removed from back, giving glimpses of musculature beneath! | Large patches of skin removed from back, giving glimpses of musculature beneath |
| BACK | 15 (20) |  | Blast tears across back leaving a nasty disintegration slash. | Blast tears across back leaving a nasty disintegration slash |
| BACK | 20 (25) |  | Scattered vaporization leaves back covered with bleeding wounds. | Scattered vaporization leaves back covered with bleeding wounds |
| BACK | 35 |  | Deep hole created in back, narrowly missing spinal cord! | Deep hole created in back, narrowly missing spinal cord |
| BACK | 40 |  | Well-focused strike generates a clean, round hole straight through the [target]! | Well-focused strike generates a clean, round hole straight |
| BACK | 50 |  | Vicious blast turns huge portions of back into red mist!  Now lacking spinal support, the [target] crumples into a heap. | Now lacking spinal support |
| BACK | 60 | F | Spinal column obliterated!  The [target]'s vertebrae reduced to a fine powder! | vertebrae reduced to a fine powder |
| BACK | 70 | F | Powerful blast instantly consumes most of the [target]!  All that remains are bloody chunks of tissue scattered about the area. | All that remains are bloody chunks of tissue scattered about the area |
| RIGHT ARM | 0 |  | Right arm grazed. |  |
| RIGHT ARM | 5 (2) |  | Unpleasant wound to right arm! | Unpleasant wound to right arm |
| RIGHT ARM | 10 (5) |  | Small patches of right forearm disappear into red mist. | forearm disappear into red mist |
| RIGHT ARM | 15 (7) |  | Grazing blast to the right arm melts skin away, exposing twitching tendons. | arm melts skin away, exposing twitching tendons |
| RIGHT ARM | 20 (10) |  | Portions of musculature disappear, revealing bones beneath! | Portions of musculature disappear, revealing bones beneath |
| RIGHT ARM | 25 (12) |  | Strike bores into right arm, causing now-weakened bones to crack. | arm, causing now-weakened bones to crack |
| RIGHT ARM | 30 (15) |  | Strike to right forearm strips away skin, exposing bleached bone and useless tendons! | forearm strips away skin, exposing bleached bone and useless tendons |
| RIGHT ARM | 35 (25) |  | Precision strike cuts cleanly across upper arm, causing forearm and elbow to fall to ground. | Precision strike cuts cleanly across upper arm, causing forearm and elbow to fall to ground |
| RIGHT ARM | 40 (30) |  | Right arm strike strips flesh and muscle down to the bone which quickly cracks off at the torso! | arm strike strips flesh and muscle down to the bone which quickly cracks off at the torso |
| RIGHT ARM | 45 (35) |  | Blast disintegrates right arm and savagely shucks huge chunks of flesh from throat! | Blast disintegrates right arm and savagely shucks huge chunks of flesh from throat |
| LEFT ARM | 0 |  | Left arm grazed. |  |
| LEFT ARM | 5 (2) |  | Unpleasant wound to left arm! | Unpleasant wound to left arm |
| LEFT ARM | 10 (5) |  | Small patches of left forearm disappear into red mist. | forearm disappear into red mist |
| LEFT ARM | 15 (7) |  | Grazing blast to the left arm melts skin away, exposing twitching tendons. | arm melts skin away, exposing twitching tendons |
| LEFT ARM | 20 (10) |  | Portions of musculature disappear, revealing bones beneath! | Portions of musculature disappear, revealing bones beneath |
| LEFT ARM | 25 (12) |  | Strike bores into left arm, causing now-weakened bones to crack. | arm, causing now-weakened bones to crack |
| LEFT ARM | 30 (15) |  | Strike to left forearm strips away skin, exposing bleached bone and useless tendons! | forearm strips away skin, exposing bleached bone and useless tendons |
| LEFT ARM | 35 (25) |  | Precision strike cuts cleanly across upper arm, causing forearm and elbow to fall to ground. | Precision strike cuts cleanly across upper arm, causing forearm and elbow to fall to ground |
| LEFT ARM | 40 (30) |  | Left arm strike strips flesh and muscle down to the bone which quickly cracks off at the torso! | arm strike strips flesh and muscle down to the bone which quickly cracks off at the torso |
| LEFT ARM | 45 (35) |  | Blast disintegrates left arm and savagely shucks huge chunks of flesh from throat! | Blast disintegrates left arm and savagely shucks huge chunks of flesh from throat |
| RIGHT HAND | 0 |  | Fingernail stripped off. | Fingernail stripped off |
| RIGHT HAND | 5 (1) |  | Patches of flesh removed from right hand. | Patches of flesh removed from right hand |
| RIGHT HAND | 10 (3) |  | Finger on right hand vaporized, leaving the [target] unable to count quite as high. | unable to count quite as high |
| RIGHT HAND | 15 (5) |  | All the fingernails are melted as the right hand takes a grazing strike. | All the fingernails are melted |
| RIGHT HAND | 20 (7) |  | Light blast to right hand drills a hole straight through palm just large enough to hold that spare wand. | hand drills a hole straight through palm just large enough to hold that spare wand |
| RIGHT HAND | 25 (8) |  | Right hand quakes as several fingers disappear one by one. | hand quakes as several fingers disappear one by one |
| RIGHT HAND | 30 (10) |  | Right hand spasms and sprays blood as flesh and bone are torn away! | hand spasms and sprays blood as flesh and bone are torn away |
| RIGHT HAND | 35 (15) |  | Right wrist vanishes, cleanly severing hand! | wrist vanishes, cleanly severing hand |
| RIGHT HAND | 40 (25) |  | With a flash of red spray, right hand disintegrates into nothing! | hand disintegrates into nothing |
| RIGHT HAND | 45 (30) |  | Blast encases right hand, instantly turning it into a fine white powder! | hand, instantly turning it into a fine white powder |
| LEFT HAND | 0 |  | Fingernail stripped off. | Fingernail stripped off |
| LEFT HAND | 5 (1) |  | Patches of flesh removed from left hand. | Patches of flesh removed from left hand |
| LEFT HAND | 10 (3) |  | Finger on left hand vaporized, leaving the [target] unable to count quite as high. | unable to count quite as high |
| LEFT HAND | 15 (5) |  | All the fingernails are melted as the left hand takes a grazing strike. | All the fingernails are melted |
| LEFT HAND | 20 (7) |  | Light blast to left hand drills a hole straight through palm just large enough to hold that spare wand. | hand drills a hole straight through palm just large enough to hold that spare wand |
| LEFT HAND | 25 (8) |  | Left hand quakes as several fingers disappear one by one. | hand quakes as several fingers disappear one by one |
| LEFT HAND | 30 (10) |  | Left hand spasms and sprays blood as flesh and bone are torn away! | hand spasms and sprays blood as flesh and bone are torn away |
| LEFT HAND | 35 (15) |  | Left wrist vanishes, cleanly severing hand! | wrist vanishes, cleanly severing hand |
| LEFT HAND | 40 (25) |  | With a flash of red spray, left hand disintegrates into nothing! | hand disintegrates into nothing |
| LEFT HAND | 45 (30) |  | Blast encases left hand, instantly turning it into a fine white powder! | hand, instantly turning it into a fine white powder |
| RIGHT LEG | 0 |  | Grazing strike to right leg. | Grazing strike |
| RIGHT LEG | 5 (4) |  | Surface of right leg etched to little effect. | leg etched to little effect |
| RIGHT LEG | 10 (8) |  | Attack removes flesh from surface of right leg, causing trickles of blood to leak out. | leg, causing trickles of blood to leak out |
| RIGHT LEG | 15 (12) |  | Chunks of flesh vaporized on right leg! | Chunks of flesh vaporized on right leg |
| RIGHT LEG | 20 (15) |  | Large portions of right thigh removed in a flash! | thigh removed in a flash |
| RIGHT LEG | 25 (18) |  | Hunks of muscle and bone disappear from right leg! | Hunks of muscle and bone disappear from right leg |
| RIGHT LEG | 30 (20) |  | Blast bores through right leg, causing femur to buckle! | leg, causing femur to buckle |
| RIGHT LEG | 35 (25) |  | Right leg violently separates from hip socket and dematerializes into bloody mass. | leg violently separates from hip socket and dematerializes into bloody mass |
| RIGHT LEG | 40 (35) |  | Right leg vaporized from thigh down, leaving nothing but dangling blood vessels and muscle! | leg vaporized from thigh down, leaving nothing but dangling blood vessels and muscle |
| RIGHT LEG | 45 (40) |  | Both legs are frightfully stripped down to the bone marrow!  Sadly, the small amounts of tissue remaining are nowhere near what is needed to support the [target]'s body. | Sadly, the small amounts of tissue remaining are nowhere near what is needed to support |
| LEFT LEG | 0 |  | Grazing strike to left leg. | Grazing strike |
| LEFT LEG | 5 (4) |  | Surface of left leg etched to little effect. | leg etched to little effect |
| LEFT LEG | 10 (8) |  | Attack removes flesh from surface of left leg, causing trickles of blood to leak out. | leg, causing trickles of blood to leak out |
| LEFT LEG | 15 (12) |  | Chunks of flesh vaporized on left leg! | Chunks of flesh vaporized on left leg |
| LEFT LEG | 20 (15) |  | Large portions of left thigh removed in a flash! | thigh removed in a flash |
| LEFT LEG | 25 (18) |  | Hunks of muscle and bone disappear from left leg! | Hunks of muscle and bone disappear from left leg |
| LEFT LEG | 30 (20) |  | Blast bores through left leg, causing femur to buckle! | leg, causing femur to buckle |
| LEFT LEG | 35 (25) |  | Left leg violently separates from hip socket and dematerializes into bloody mass. | leg violently separates from hip socket and dematerializes into bloody mass |
| LEFT LEG | 40 (35) |  | Left leg vaporized from thigh down, leaving nothing but dangling blood vessels and muscle! | leg vaporized from thigh down, leaving nothing but dangling blood vessels and muscle |
| LEFT LEG | 45 (40) |  | Both legs are frightfully stripped down to the bone marrow!  Sadly, the small amounts of tissue remaining are nowhere near what is needed to support the [target]'s body. | Sadly, the small amounts of tissue remaining are nowhere near what is needed to support |

## Disruption  (130 messages, 21 fatal)

| sec | rank | F | message | current match |
|---|---|---|---|---|
| HEAD | 0 |  | ? |  |
| HEAD | 5 |  | Veins bulge on forehead, giving the [target] a mild headache. | a mild headache |
| HEAD | 10 |  | Blood vessels in the [target]'s forehead burst, spraying blood everywhere. | forehead burst, spraying blood everywhere |
| HEAD | 15 |  | The [target]'s skull cracks with an audible "Pop"! | skull cracks with an audible "Pop |
| HEAD | 20 |  | The [target]'s ears swell, bursting its eardrums. | ears swell, bursting its eardrums |
| HEAD | 25 |  | Brain swells suddenly, unfortunately the [target]'s skull doesn't. | Brain swells suddenly, unfortunately |
| HEAD | 30 | F | Skull and surrounding flesh disintegrate.  The [target] falls to the ground dead. | Skull and surrounding flesh disintegrate |
| HEAD | 35 | F | The [target]'s head explodes like an overripe melon. | head explodes like an overripe melon |
| HEAD | 40 | F | Skull shatters into sharp spikes which are driven into the [target]'s brain. | Skull shatters into sharp spikes which are driven |
| HEAD | 50 | F | The [target]'s head vibrates violently, before melting away in a rush of heat. | head vibrates violently, before melting away in a rush of heat |
| NECK | 0 |  | ? |  |
| NECK | 5 |  | Throat strike causes the [target] to cough. | Throat strike causes |
| NECK | 10 |  | Small veins in the [target]'s neck burst, the blood flows freely. | neck burst, the blood flows freely |
| NECK | 15 |  | The [target]'s neck snapped violently by spasming muscles. | neck snapped violently by spasming muscles |
| NECK | 20 |  | The [target]'s neck bones snap. Head looks precariously balanced now. | Head looks precariously balanced now |
| NECK | 25 |  | Vertebrae swell in the [target]'s neck, thrusting through the skin. | neck, thrusting through the skin |
| NECK | 30 | F | Vertebrae ripped from body!  The [target]'s head falls into shoulders. | head falls into shoulders |
| NECK | 35 | F | Larynx swells and explodes, but the [target] won't be needing it anymore anyway. | won't be needing it anymore anyway |
| NECK | 40 | F | The [target]'s neck muscles contract violently, severing head from shoulders. | neck muscles contract violently, severing head from shoulders |
| NECK | 50 | F | The [target]'s neck explodes launching its head into the air. | neck explodes launching its head into the air |
| RIGHT EYE | 0 |  | ? |  |
| RIGHT EYE | 5 |  | The [target]'s right eye swells suddenly, causing great pain. | eye swells suddenly, causing great pain |
| RIGHT EYE | 10 |  | The [target]'s eye swells but settles back into its socket. | eye swells but settles back into its socket |
| RIGHT EYE | 15 |  | Blood in the [target]'s right eye boils.  Red steam rises from socket. | right eye boils.  Red steam rises from socket |
| RIGHT EYE | 20 |  | Blood flow to the [target]'s right eye cut off. |  |
| RIGHT EYE | 25 |  | The [target]'s eye explodes, showering you with gore. | eye explodes, showering you with gore |
| RIGHT EYE | 30 | F | The [target]'s eye swells and cracks head open!  Instant death. | eye swells and cracks head open |
| RIGHT EYE | 40 | F | The [target]'s right eye boils away, stewing the brain as well. | eye boils away, stewing the brain as well |
| RIGHT EYE | 45 | F | The [target]'s cheek shatters, driving bones into eye. | cheek shatters, driving bones into eye |
| RIGHT EYE | 50 | F | The [target]'s eye explodes shattering the skull into a thousand pieces. | eye explodes shattering the skull into a thousand pieces |
| LEFT EYE | 0 |  | ? |  |
| LEFT EYE | 5 |  | The [target]'s left eye swells suddenly, causing great pain. | eye swells suddenly, causing great pain |
| LEFT EYE | 10 |  | The [target]'s eye swells but settles back into its socket. | eye swells but settles back into its socket |
| LEFT EYE | 15 |  | Blood in the [target]'s left eye boils.  Red steam rises from socket. | left eye boils.  Red steam rises from socket |
| LEFT EYE | 20 |  | Blood flow to the [target]'s left eye cut off. |  |
| LEFT EYE | 25 |  | The [target]'s eye explodes, showering you with gore. | eye explodes, showering you with gore |
| LEFT EYE | 30 | F | The [target]'s eye swells and cracks head open!  Instant death. | eye swells and cracks head open |
| LEFT EYE | 40 | F | The [target]'s left eye boils away, stewing the brain as well. | eye boils away, stewing the brain as well |
| LEFT EYE | 45 | F | The [target]'s cheek shatters, driving bones into eye. | cheek shatters, driving bones into eye |
| LEFT EYE | 50 | F | The [target]'s eye explodes shattering the skull into a thousand pieces. | eye explodes shattering the skull into a thousand pieces |
| CHEST | 0 |  | ? |  |
| CHEST | 5 |  | Chest spasm makes it hard for the [target] to breathe. | Chest spasm makes it hard for |
| CHEST | 10 |  | Blood boils in the [target]'s chest. |  |
| CHEST | 15 |  | The [target]'s ribs warp and crack violently. | ribs warp and crack violently |
| CHEST | 20 |  | Rib bones snap and protrude from the [target]'s chest. | Rib bones snap and protrude |
| CHEST | 25 |  | Pressure on the [target]'s organs causes internal bleeding. | organs causes internal bleeding |
| CHEST | 30 |  | One lung bursts in the [target]'s chest! | One lung bursts in |
| CHEST | 50 |  | The [target]'s lungs burst and so does its chest. | lungs burst and so does its chest |
| CHEST | 60 |  | You send a blood clot to the [target]'s heart, causing massive damage. | heart, causing massive damage |
| CHEST | 70 | F | Heart explodes rupturing the [target]'s chest. | Heart explodes rupturing the |
| ABDOMEN | 0 |  | ? |  |
| ABDOMEN | 5 |  | The [target] doubles over with stomach cramps. | doubles over with stomach cramps |
| ABDOMEN | 10 |  | The [target]'s stomach muscles jerk uncontrollably. | stomach muscles jerk uncontrollably |
| ABDOMEN | 15 |  | The [target]'s intestines knot themselves.  Painful. | intestines knot themselves |
| ABDOMEN | 20 |  | The [target]'s stomach muscles ripped apart violently. | stomach muscles ripped apart violently |
| ABDOMEN | 25 |  | Flesh and muscle stripped from the [target]'s stomach. | Flesh and muscle stripped |
| ABDOMEN | 30 |  | The [target]'s stomach muscles explode violently. | stomach muscles explode violently |
| ABDOMEN | 50 |  | Gaping hole punched through the [target]'s stomach! | Gaping hole punched through |
| ABDOMEN | 60 | F | The [target]'s stomach rips through flesh and explodes. | stomach rips through flesh and explodes |
| ABDOMEN | 70 | F | The [target]'s midsection swells painfully then bursts, sending the [target] everywhere. | midsection swells painfully then bursts, sending |
| BACK | 0 |  | ? |  |
| BACK | 5 |  | Strike to the [target]'s back causes minor spasms. | back causes minor spasms |
| BACK | 10 |  | The [target]'s vertebrae vibrate causing extreme pain. | vertebrae vibrate causing extreme pain |
| BACK | 15 |  | Strips of flesh flayed from the [target]'s back. | Strips of flesh flayed |
| BACK | 20 |  | The [target]'s spine warps and protrudes through skin. | spine warps and protrudes through skin |
| BACK | 25 |  | The [target]'s spinal cord swells, causing momentary paralysis. | spinal cord swells, causing momentary paralysis |
| BACK | 30 |  | Gaping hole torn in the [target]'s back exposing ribs. | back exposing ribs |
| BACK | 50 |  | The [target]'s spinal fluid boils, rupturing spinal cord. | spinal fluid boils, rupturing spinal cord |
| BACK | 60 | F | Both the [target]'s kidneys rupture.  Death is quick and painful. | kidneys rupture.  Death is quick and painful |
| BACK | 70 | F | Spine ripped from the [target]s's body and thrown to the ground. | body and thrown to the ground |
| RIGHT ARM | 0 |  | ? |  |
| RIGHT ARM | 5 |  | Strike to the [target]'s right arm sprains biceps. | arm sprains biceps |
| RIGHT ARM | 10 |  | Tendons in the [target]'s weapon arm snap. | weapon arm snap |
| RIGHT ARM | 15 |  | Large lesions sprout on the [target]'s weapon arm. | Large lesions sprout on |
| RIGHT ARM | 20 |  | Major bones in the [target]'s right arm crack loudly! | arm crack loudly |
| RIGHT ARM | 25 |  | Blood in the [target]'s weapon arm boils, sending up a red mist. | weapon arm boils, sending up a red mist |
| RIGHT ARM | 30 |  | Bones shatter in the [target]'s weapon arm. | Bones shatter |
| RIGHT ARM | 35 |  | The [target]'s elbow explodes sending bone fragments flying. | elbow explodes sending bone fragments flying |
| RIGHT ARM | 40 |  | You shatter all of the [target]'s bones from the elbow down, leaving only bloody strips of flesh behind. | bones from the elbow down, leaving only bloody strips of flesh behind |
| RIGHT ARM | 45 |  | The [target]'s shoulder joint explodes, severing weapon arm. | shoulder joint explodes, severing weapon arm |
| LEFT ARM | 0 |  | ? |  |
| LEFT ARM | 5 |  | Strike to the [target]'s left arm sprains biceps. | arm sprains biceps |
| LEFT ARM | 10 |  | Tendons in the [target]'s shield arm snap. | shield arm snap |
| LEFT ARM | 15 |  | Large lesions sprout on the [target]'s shield arm. | Large lesions sprout on |
| LEFT ARM | 20 |  | Major bones in the [target]'s left arm crack loudly! | arm crack loudly |
| LEFT ARM | 25 |  | Blood in the [target]'s shield arm boils, sending up a red mist. | shield arm boils, sending up a red mist |
| LEFT ARM | 30 |  | Bones shatter in the [target]'s shield arm. | Bones shatter |
| LEFT ARM | 35 |  | The [target]'s elbow explodes sending bone fragments flying. | elbow explodes sending bone fragments flying |
| LEFT ARM | 40 |  | You shatter all of the [target]'s bones from the elbow down, leaving only bloody strips of flesh behind. | bones from the elbow down, leaving only bloody strips of flesh behind |
| LEFT ARM | 45 |  | The [target]'s shoulder joint explodes, severing shield arm. | shoulder joint explodes, severing shield arm |
| RIGHT HAND | 0 |  | ? |  |
| RIGHT HAND | 5 |  | Spasm to the [target]'s right hand. |  |
| RIGHT HAND | 10 |  | The [target]'s finger twitches, then explodes. | finger twitches, then explodes |
| RIGHT HAND | 15 |  | Oozing sores appear on the [target]'s right hand. | Oozing sores appear on |
| RIGHT HAND | 20 |  | Bones from several fingers driven through the [target]'s skin. | Bones from several fingers driven |
| RIGHT HAND | 25 |  | Flesh flayed from the [target]'s right hand. | Flesh flayed |
| RIGHT HAND | 30 |  | The [target]'s thumb explodes in a shower of flesh and bone fragments. | thumb explodes in a shower of flesh and bone fragments |
| RIGHT HAND | 35 |  | The [target]'s wrist bones explode, leaving only a stump. | wrist bones explode, leaving only a stump |
| RIGHT HAND | 40 |  | The [target]'s right hand swells and explodes into thousands of pieces. | hand swells and explodes into thousands of pieces |
| RIGHT HAND | 45 |  | The [target]'s entire hand explodes in a shower of blood and bone. | entire hand explodes in a shower of blood and bone |
| LEFT HAND | 0 |  | ? |  |
| LEFT HAND | 5 |  | Spasm to the [target]'s left hand. |  |
| LEFT HAND | 10 |  | The [target]'s finger twitches, then explodes. | finger twitches, then explodes |
| LEFT HAND | 15 |  | Oozing sores appear on the [target]'s left hand. | Oozing sores appear on |
| LEFT HAND | 20 |  | Bones from several fingers driven through the [target]'s skin. | Bones from several fingers driven |
| LEFT HAND | 25 |  | Flesh flayed from the [target]'s left hand. | Flesh flayed |
| LEFT HAND | 30 |  | The [target]'s thumb explodes in a shower of flesh and bone fragments. | thumb explodes in a shower of flesh and bone fragments |
| LEFT HAND | 35 |  | The [target]'s wrist bones explode, leaving only a stump. | wrist bones explode, leaving only a stump |
| LEFT HAND | 40 |  | The [target]'s left hand swells and explodes into thousands of pieces. | hand swells and explodes into thousands of pieces |
| LEFT HAND | 45 |  | The [target]'s hand explodes in a shower of blood and bone. | hand explodes in a shower of blood and bone |
| RIGHT LEG | 0 |  | ? |  |
| RIGHT LEG | 5 |  | The [target]'s right leg jerks momentarily. | leg jerks momentarily |
| RIGHT LEG | 10 |  | You snap the tendons in the [target]'s foot.  Looks painful. | You snap the tendons |
| RIGHT LEG | 15 |  | Minor muscle tearing on the [target]'s right leg. | Minor muscle tearing on |
| RIGHT LEG | 20 |  | Major bones in the [target]'s right leg crack loudly! | leg crack loudly |
| RIGHT LEG | 25 |  | Flesh bubbles on the [target]'s right leg. | Flesh bubbles |
| RIGHT LEG | 30 |  | Bones shatter in the [target]'s leg! | Bones shatter |
| RIGHT LEG | 35 |  | The [target]'s kneecap explodes sending bone fragments flying. | kneecap explodes sending bone fragments flying |
| RIGHT LEG | 40 |  | You disintegrate the [target]'s right leg from the knee down. | leg from the knee down |
| RIGHT LEG | 45 |  | The [target]'s right leg crumbles briefly and explodes in a shower of gore. | leg crumbles briefly and explodes in a shower of gore |
| LEFT LEG | 0 |  | ? |  |
| LEFT LEG | 5 |  | The [target]'s left leg jerks momentarily. | leg jerks momentarily |
| LEFT LEG | 10 |  | You snap the tendons in the [target]'s foot.  Looks painful. | You snap the tendons |
| LEFT LEG | 15 |  | Minor muscle tearing on the [target]'s left leg. | Minor muscle tearing on |
| LEFT LEG | 20 |  | Major bones in the [target]'s left leg crack loudly! | leg crack loudly |
| LEFT LEG | 25 |  | Flesh bubbles on the [target]'s left leg. | Flesh bubbles |
| LEFT LEG | 30 |  | Bones shatter in the [target]'s leg! | Bones shatter |
| LEFT LEG | 35 |  | The [target]'s kneecap explodes sending bone fragments flying. | kneecap explodes sending bone fragments flying |
| LEFT LEG | 40 |  | You disintegrate the [target]'s left leg from the knee down. | leg from the knee down |
| LEFT LEG | 45 |  | The [target]'s left leg crumbles briefly and explodes in a shower of gore. | leg crumbles briefly and explodes in a shower of gore |

## Non-corporeal  (133 messages, 0 fatal)

| sec | rank | F | message | current match |
|---|---|---|---|---|
| HEAD | V |  | Light tap to the [target]'s head ruffles its appearance. | head ruffles its appearance |
| HEAD | V |  | Quick blow to the head. Swirls of vapor dance around the [target]'s head. | Swirls of vapor dance around |
| HEAD | V |  | Light strike to the [target]'s head. A wisp of vapor trickles earthward. | A wisp of vapor trickles earthward |
| HEAD | V |  | Top of the head momentarily flattened. | Top of the head momentarily flattened |
| HEAD | V |  | Swift strike would have hit more than an ear, if only it were there. | Swift strike would have hit more than an ear, if only it were there |
| HEAD | V |  | The [target]'s head wavers as your attack passes right through it! | head wavers as your attack passes |
| HEAD | V |  | Strong blow to the head! The [target] enjoys the breeze. | Strong blow to the head |
| HEAD | V |  | Your attack whistles right through the [target]'s face. Dimples! | attack whistles right through |
| HEAD | V |  | The [target]'s head is split cleanly in two, but reseals from the neck up! | head is split cleanly in two, but reseals from the neck up |
| HEAD | V |  | Strong attack separates head from shoulders. Head disappears in the breeze as a new one forms on the [target]'s shoulders! | Head disappears in the breeze as a new one forms |
| NECK | V |  | Light blow to the neck causes even more unpleasant groans and wails. | Light blow to the neck causes even more unpleasant groans and wails |
| NECK | V |  | Weak blow to neck wouldn't have scared the [target] even if it were still alive. | even if it were still alive |
| NECK | V |  | Flashy attack passes through the side of the neck. Ethereal fluids spray forth and quickly vanish into vapor! | Ethereal fluids spray forth and quickly vanish into vapor |
| NECK | V |  | Smoky tendrils rise from neck as your attack sweeps through. | Smoky tendrils rise from neck as your attack sweeps |
| NECK | V |  | Powerful hit to the [target]'s neck leaves trails of vapor in its wake! | neck leaves trails of vapor in its wake |
| NECK | V |  | Strong attack rips through the neck! To your horror, the [target]'s substance flows around the wound without leaving a trace! | substance flows around the wound without leaving a trace |
| NECK | V |  | The [target] wails eerily as your blow passes through its vocal cords. | wails eerily as your blow passes through its vocal cords |
| NECK | V |  | Vicious blow to neck might have been fatal a few centuries ago. | Vicious blow to neck might have been fatal a few centuries ago |
| NECK | V |  | Brutal blow to the neck sends head flying! The head floats up and settles back in place as easily as a hat. What is this, a haberdashery? | The head floats up and settles back in place as easily as a hat |
| NECK | ? |  | N/A |  |
| NECK | V |  | Tremendous strike! Vapor rushes from the neck following the blow! | Vapor rushes from the neck following the blow |
| RIGHT EYE | V |  | The [target] blinks as the strike grazes the right eye. | blinks as the strike grazes |
| RIGHT EYE | V |  | Quick strike to the face! Just nicked an eyelid! | Quick strike to the face |
| RIGHT EYE | V |  | Nasty strike to the right eye causes it to dim a moment. | eye causes it to dim a moment |
| RIGHT EYE | V |  | Decent shot to the right eye would have blinded a normal foe! | eye would have blinded a normal foe |
| RIGHT EYE | V |  | Quick strike sinks deep into the right eye socket. | Quick strike sinks deep into the right eye socket |
| RIGHT EYE | V |  | Hard blow strikes deep into the right eye socket. Within moments the eyeball pops back out! | Hard blow strikes deep into the right eye socket |
| RIGHT EYE | V |  | Smash to the cheek deforms right eye socket. Vapor swirls as the ethereal bones reform. | Smash to the cheek deforms right eye socket |
| RIGHT EYE | V |  | Blow to the right eye slides through head. The [target] twitches violently, then shudders slightly as the wound seals. | twitches violently, then shudders slightly as the wound seals |
| RIGHT EYE | V |  | Hard blast to the side of the right eye. Strike carries right on through the bridge of the nose, the other eye, and the rest of the head! | on through the bridge of the nose, the other eye, and the rest of the head |
| RIGHT EYE | V |  | Surgical strike to the right eye removes the top of the head! The [target] goes still for a moment while its head reshapes. | Surgical strike to the right eye removes the top of the head |
| LEFT EYE | V |  | The [target] blinks as the strike grazes the left eye. | blinks as the strike grazes |
| LEFT EYE | V |  | Quick strike to the face! Just nicked an eyelid! | Quick strike to the face |
| LEFT EYE | V |  | Nasty strike to the left eye causes it to dim a moment. | eye causes it to dim a moment |
| LEFT EYE | V |  | Decent shot to the left eye would have blinded a normal foe! | eye would have blinded a normal foe |
| LEFT EYE | V |  | Quick strike sinks deep into the left eye socket. | Quick strike sinks deep into the left eye socket |
| LEFT EYE | V |  | Hard blow strikes deep into the left eye socket. Within moments the eyeball pops back out! | Hard blow strikes deep into the left eye socket |
| LEFT EYE | V |  | Smash to the cheek deforms left eye socket. Vapor swirls as the ethereal bones reform. | Smash to the cheek deforms left eye socket |
| LEFT EYE | V |  | Blow to the left eye slides through head. The [target] twitches violently, then shudders slightly as the wound seals. | twitches violently, then shudders slightly as the wound seals |
| LEFT EYE | V |  | Hard blast to the side of the left eye. Strike carries right on through the bridge of the nose, the other eye, and the rest of the head! | on through the bridge of the nose, the other eye, and the rest of the head |
| LEFT EYE | V |  | Surgical strike to the left eye removes the top of the head! The [target] goes still for a moment while its head reshapes. | Surgical strike to the left eye removes the top of the head |
| CHEST | V |  | Did you even connect? Nope, that was just wind damage. | Nope, that was just wind damage |
| CHEST | V |  | Weak blow leaves a brief imprint on the [target]'s chest! | Weak blow leaves a brief imprint |
| CHEST | V |  | Direct assault cleaves straight through the breastbone. Alas, it mends before you can make a wish. | Direct assault cleaves straight through the breastbone |
| CHEST | V |  | The [target] fades for a second as the blow passes through the chest. | fades for a second as the blow passes through the chest |
| CHEST | V |  | Smash to the chest! Good thing there were no ribs there to shatter. | Good thing there were no ribs there to shatter |
| CHEST | V |  | Attack whistles right through the chest! It's like fighting fog! | attack whistles right through |
| CHEST | V |  | Strong hit to the chest! Tendrils of mist explode as the strike passes right through. | Tendrils of mist explode as the strike passes right |
| CHEST | V |  | Brutal assault cuts a swath through the torso! Fortunately for the [target], it doesn't need lungs. | Brutal assault cuts a swath through the torso |
| CHEST | V |  | Mighty blow rips through the [target]'s chest, causing it to pause as it reforms. | chest, causing it to pause as it reforms |
| CHEST | V |  | Massive strike to the chest crashes through the [target]'s back in a cloud of vapor. | Massive strike to the chest crashes |
| ABDOMEN | V |  | Half-hearted strike to the midsection. The [target] seems unfazed. | Half-hearted strike to the midsection |
| ABDOMEN | V |  | Quick blow to the belly causes the [target] to drift backwards slightly. | Quick blow to the belly causes |
| ABDOMEN | V |  | Glancing blow to the stomach. Good thing it won't be eating soon. | Good thing it won't be eating soon |
| ABDOMEN | V |  | Hit passes right through the midsection. Nothing hurts like an empty stomach. | Nothing hurts like an empty stomach |
| ABDOMEN | V |  | Strike swipes cleanly through the abdomen, but seals up a moment later! | Strike swipes cleanly through the abdomen, but seals up a moment later |
| ABDOMEN | V |  | Massive blow strikes the [target] and drives it back! Good thing those ribs aren't made of bone. | Good thing those ribs aren't made of bone |
| ABDOMEN | V |  | Strong strike splits the belly open, revealing ghostly organs. Haggis anyone? | Strong strike splits the belly open, revealing ghostly organs |
| ABDOMEN | V |  | Hard strike to the abdomen. Ethereal entrails seem to spill from the [target]'s mangled substance, vanishing into misty tendrils as they strike the ground. | mangled substance, vanishing into misty tendrils as they strike the ground |
| ABDOMEN | V |  | Strike to the abdomen goes right through, leaving misty trails in its wake. | through, leaving misty trails in its wake |
| ABDOMEN | V |  | Amazing strike enters one side and exits the other, neatly cutting the [target] in half! | Amazing strike enters one side and exits the other, neatly cutting |
| BACK | V |  | Light tap to the [target]'s lower back. Seems more of an annoyance than anything else. | Seems more of an annoyance than anything else |
| BACK | V |  | Misjudged timing. You barely catch the [target] in the back! | Misjudged timing |
| BACK | V |  | Hard strike connects with the [target]'s back! A thin arc of mist spews forth, evaporating quickly. | A thin arc of mist spews forth, evaporating quickly |
| BACK | V |  | Quick strike connects with the [target]'s lower back! Luckily there was nothing vital there. | Luckily there was nothing vital there |
| BACK | V |  | Hard shot to the [target]'s back sends it drifting forward! | back sends it drifting forward |
| BACK | V |  | Deft blow to the spine cuts along the ethereal bones. Fillet of soul? | Deft blow to the spine cuts along the ethereal bones |
| BACK | V |  | Attack whistles right through the lower back encountering little resistance! | through the lower back encountering little resistance |
| BACK | V |  | Body swirls violently from a strong hit to the back. Neat effect! | Body swirls violently from a strong hit to the back |
| BACK | V |  | Incredible strike to the [target]'s back smashes through the chest! Too bad it melts back together. | back smashes through the chest |
| BACK | V |  | Amazing shot cleaves the torso in half at the waist! You watch agape as the misty form knits itself back together! | You watch agape as the misty form knits itself back together |
| RIGHT ARM | V |  | Ineffectual strike knocks a wisp of ether from the [target]'s right arm. | Ineffectual strike knocks a wisp of ether |
| RIGHT ARM | V |  | Glancing blow to the right arm leaves a trail of vapor in its wake. | arm leaves a trail of vapor in its wake |
| RIGHT ARM | V |  | Large gash to the right arm seals as strike passes through. | arm seals as strike passes |
| RIGHT ARM | V |  | Quick strike rips right arm open! To your dismay it quickly closes on its own. | To your dismay it quickly closes on its own |
| RIGHT ARM | V |  | Strong hit rips arm from wrist to elbow. The wound vanishes as the ethereal flesh swirls around in chaotic patterns. | The wound vanishes as the ethereal flesh swirls around in chaotic patterns |
| RIGHT ARM | V |  | Good hit! Right shoulder is ripped from its socket, then wriggles back into place. | shoulder is ripped from its socket, then wriggles back into place |
| RIGHT ARM | V |  | Hard strike shatters arm into vapor. The arm reforms before your eyes! | Hard strike shatters arm into vapor |
| RIGHT ARM | V |  | Right arm ripped in half at elbow! The fallen arm evaporates as a new one materializes. | The fallen arm evaporates as a new one materializes |
| RIGHT ARM | V |  | A massive blow to the right shoulder hoists the [target] high into the air. It hangs there a moment, suspended, before falling forward. | It hangs there a moment, suspended, before falling forward |
| RIGHT ARM | V |  | Huge hit explodes right arm into cold, viscous mist. When you look again, the arm has reformed. | When you look again, the arm has reformed |
| RIGHT ARM | ? |  | N/A |  |
| LEFT ARM | V |  | Ineffectual strike knocks a wisp of ether from the [target]'s left arm. | Ineffectual strike knocks a wisp of ether |
| LEFT ARM | V |  | Glancing blow to the left arm leaves a trail of vapor in its wake. | arm leaves a trail of vapor in its wake |
| LEFT ARM | V |  | Large gash to the left arm seals as strike passes through. | arm seals as strike passes |
| LEFT ARM | V |  | Quick strike rips left arm open! To your dismay it quickly closes on its own. | To your dismay it quickly closes on its own |
| LEFT ARM | V |  | Strong hit rips arm from wrist to elbow. The wound vanishes as the ethereal flesh swirls around in chaotic patterns. | The wound vanishes as the ethereal flesh swirls around in chaotic patterns |
| LEFT ARM | V |  | Good hit! Left shoulder is ripped from its socket, then wriggles back into place. | shoulder is ripped from its socket, then wriggles back into place |
| LEFT ARM | V |  | Hard strike shatters arm into vapor. The arm reforms before your eyes! | Hard strike shatters arm into vapor |
| LEFT ARM | V |  | Left arm ripped in half at the elbow! The fallen arm evaporates as a new one materializes. | The fallen arm evaporates as a new one materializes |
| LEFT ARM | V |  | A massive blow to the left shoulder hoists the [target] high into the air. It hangs there a moment, suspended, before falling forward. | It hangs there a moment, suspended, before falling forward |
| LEFT ARM | V |  | Huge hit explodes left arm into cold, viscous mist. When you look again, the arm has reformed. | When you look again, the arm has reformed |
| LEFT ARM | ? |  | N/A |  |
| RIGHT HAND | V |  | Weak blow to the hand. Rapping its knuckles will only make it mad! | Rapping its knuckles will only make it mad |
| RIGHT HAND | V |  | A weak slap on the wrist. That's not going to reform a soul. | That's not going to reform a soul |
| RIGHT HAND | V |  | Weak attack slips silently through the [target]'s fingers, stirring the breeze. | fingers, stirring the breeze |
| RIGHT HAND | V |  | The [target] glares maliciously as the strike slides through its right hand. | glares maliciously as the strike slides |
| RIGHT HAND | V |  | Hard blow to the right hand sends fingers flying. Alas, they reform soundlessly from thin air. | Hard blow to the right hand sends fingers flying |
| RIGHT HAND | V |  | A fine blow splits the back of the hand. Tendrils of vapor intertwine as the wound seals before your eyes. | Tendrils of vapor intertwine as the wound seals before your eyes |
| RIGHT HAND | V |  | The [target]'s hand explodes from the brutal strike! Trails of ether spurt high into the air in all directions. | Trails of ether spurt high into the air in all directions |
| RIGHT HAND | V |  | Strong smash to the right hand! The [target] quails and sinks momentarily as its right hand reforms before your eyes. | Strong smash to the right hand |
| RIGHT HAND | V |  | A strong blow cleaves the right wrist! The hand dangles, spinning slowly, and then snaps back in place! | The hand dangles, spinning slowly, and then snaps back in place |
| RIGHT HAND | V |  | A mighty attack shatters the right hand into a thousand fragments. To your horror, the fragments turn to vapor and reform the hand. | To your horror, the fragments turn to vapor and reform the hand |
| LEFT HAND | V |  | Weak blow to the hand. Rapping its knuckles will only make it mad! | Rapping its knuckles will only make it mad |
| LEFT HAND | V |  | A weak slap on the wrist. That's not going to reform a soul. | That's not going to reform a soul |
| LEFT HAND | V |  | Weak attack slips silently through the [target]'s fingers, stirring the breeze. | fingers, stirring the breeze |
| LEFT HAND | V |  | The [target] glares maliciously as the strike slides through its left hand. | glares maliciously as the strike slides |
| LEFT HAND | V |  | Hard blow to the left hand sends fingers flying. Alas, they reform soundlessly from thin air. | Hard blow to the left hand sends fingers flying |
| LEFT HAND | V |  | A fine blow splits the back of the hand. Tendrils of vapor intertwine as the wound seals before your eyes. | Tendrils of vapor intertwine as the wound seals before your eyes |
| LEFT HAND | V |  | The [target]'s hand explodes from the brutal strike! Trails of ether spurt high into the air in all directions. | Trails of ether spurt high into the air in all directions |
| LEFT HAND | V |  | Strong smash to the left hand! The [target] quails and sinks momentarily as its left hand reforms before your eyes. | hand reforms before your eyes |
| LEFT HAND | V |  | A strong blow cleaves the left wrist! The hand dangles, spinning slowly, and then snaps back in place! | The hand dangles, spinning slowly, and then snaps back in place |
| LEFT HAND | V |  | A mighty attack shatters the left hand into a thousand fragments. To your horror, the fragments turn to vapor and reform the hand. | To your horror, the fragments turn to vapor and reform the hand |
| RIGHT LEG | V |  | A weak tap grazes the right ankle. Feeling nervous yet? | Feeling nervous yet |
| RIGHT LEG | V |  | Right ankle stung! The [target] stamps in silent annoyance. | stamps in silent annoyance |
| RIGHT LEG | V |  | Wild attack passes through the right leg, viciously assaulting the air! | leg, viciously assaulting the air |
| RIGHT LEG | V |  | A strong blow bursts the right calf open in a spray of vapor. New muscle erupts from the middle of the wound, consuming the injured tissue. | New muscle erupts from the middle of the wound, consuming the injured tissue |
| RIGHT LEG | V |  | A fine strike pins the right leg for an instant. The [target] looks miffed. | A fine strike pins |
| RIGHT LEG | V |  | Quick strike to the right leg! The [target] makes no bones about it. | Quick strike to the right leg |
| RIGHT LEG | V |  | Strong assault amputates the leg at the knee. It floats in the air a moment before drifting back into place! | It floats in the air a moment before drifting back into place |
| RIGHT LEG | V |  | Painful attack flays the leg from thigh to calf. New skin lies, snakelike, beneath the old. | Painful attack flays the leg from thigh to calf |
| RIGHT LEG | V |  | Massive blow obliterates the right knee. The [target] falters as a sickly light flows freely down its leg. | falters as a sickly light flows freely down its leg |
| RIGHT LEG | V |  | Huge strike vaporizes the right thigh. The [target] convulses, falling inward upon itself while the leg mends. | convulses, falling inward upon itself while the leg mends |
| LEFT LEG | V |  | A weak tap grazes the left ankle. Feeling nervous yet? | Feeling nervous yet |
| LEFT LEG | V |  | Left ankle stung! The [target] stamps in silent annoyance. | stamps in silent annoyance |
| LEFT LEG | V |  | Wild attack passes through the left leg, viciously assaulting the air! | leg, viciously assaulting the air |
| LEFT LEG | V |  | A strong blow bursts the left calf open in a spray of vapor. New muscle erupts from the middle of the wound, consuming the injured tissue. | New muscle erupts from the middle of the wound, consuming the injured tissue |
| LEFT LEG | V |  | A fine strike pins the left leg for an instant. The [target] looks miffed. | A fine strike pins |
| LEFT LEG | V |  | Quick strike to the left leg! The [target] makes no bones about it. | Quick strike to the left leg |
| LEFT LEG | V |  | Strong assault amputates the leg at the knee. It floats in the air a moment before drifting back into place! | It floats in the air a moment before drifting back into place |
| LEFT LEG | V |  | Painful attack flays the leg from thigh to calf. New skin lies, snakelike, beneath the old. | Painful attack flays the leg from thigh to calf |
| LEFT LEG | V |  | Massive blow obliterates the left knee. The [target] falters as a sickly light flows freely down its leg. | falters as a sickly light flows freely down its leg |
| LEFT LEG | V |  | Huge strike vaporizes the left thigh. The [target] convulses, falling inward upon itself while the leg mends. | convulses, falling inward upon itself while the leg mends |

## Plasma  (130 messages, 22 fatal)

| sec | rank | F | message | current match |
|---|---|---|---|---|
| HEAD | 0 |  | A brilliant burst of energy appears over the [target]'s head, an unhealthy heat. | A brilliant burst of energy appears over |
| HEAD | 5 |  | Light burns to the [target]'s head. |  |
| HEAD | 10 (8) |  | Burst of brilliant energy to head stuns the [target] for an instant. | for an instant |
| HEAD | 15 (10) |  | Stunning blast of plasma reduces the [target]'s nose to a blackened stump. | Stunning blast of plasma reduces |
| HEAD | 20 |  | Wreath of energy burns away the [target]'s hair and leaves skin blackened! | hair and leaves skin blackened |
| HEAD | 25 |  | Streaking blast of plasma fills the [target]'s mouth searing away the tongue! | Streaking blast of plasma fills |
| HEAD | 30 | F | Hole drilled clean through the [target]'s forehead, instant ventilation! | forehead, instant ventilation |
| HEAD | 35 | F | Terrifying surge of plasma reduces the [target]'s head to burnt meat. | Terrifying surge of plasma reduces |
| HEAD | 40 | F | Slicing arc of plasma slices the top of the [target]'s head off! | Slicing arc of plasma slices the top |
| HEAD | 50 | F | Head and most of upper body turned into a smoking pile of gore! | Head and most of upper body turned into a smoking pile of gore |
| NECK | 0 |  | Blue flames form a shimmering necklace around the [target]'s throat. | Blue flames form a shimmering necklace around |
| NECK | 5 (2) |  | Insignificant burns to the [target]'s neck. | Insignificant burns |
| NECK | 10 (5) |  | Plasma strike to neck constricts throat causing the [target] to choke. | Plasma strike to neck constricts throat causing |
| NECK | 15 (10) |  | Precise burst of energy causes the [target]'s neck to blacken and peel. | Precise burst of energy causes |
| NECK | 20 (19) |  | Plasma encircles the [target]'s neck causing skin to shrivel and bleed! | neck causing skin to shrivel and bleed |
| NECK | 25 (15) | F | Crackling blue plasma roasts a smoking hole in the [target]'s neck! | Crackling blue plasma roasts a smoking hole |
| NECK | 30 (20) | F | Intense blast causes the [target]'s carotid arteries to explode! | carotid arteries to explode |
| NECK | 35 (25) | F | Shimmering beam of plasma nearly shears the [target]'s neck in two! | Shimmering beam of plasma nearly shears |
| NECK | 40 (30) | F | Powerful lash of plasma travels down neck to the [target]'s heart! | Powerful lash of plasma travels down neck |
| NECK | 45 (40) | F | The [target]'s neck and shoulders blasted away by intense wave of plasma. | neck and shoulders blasted away by intense wave of plasma |
| RIGHT EYE | 0 |  | The <target> blinks away tears from a brilliant flash of light. | The <target> blinks away tears from a brilliant flash of light |
| RIGHT EYE | 5 (1) |  | Flash burns to eye momentarily blind the [target]. | Flash burns to eye momentarily blind |
| RIGHT EYE | 10 (6) |  | Intense blast to the [target]'s eyelid causes it to sizzle and pop. | eyelid causes it to sizzle and pop |
| RIGHT EYE | 15 (14) |  | Blistering bolt of energy causes the [target]'s eyelid to burn to a crisp! | Blistering bolt of energy causes |
| RIGHT EYE | 20 (30) |  | The [target]'s eye blackens and pops leaving a smoking hole behind! | eye blackens and pops leaving a smoking hole behind |
| RIGHT EYE | 25 (30) |  | The [target]'s eye is blown out of socket by powerful bolt of plasma! | eye is blown out of socket by powerful bolt of plasma |
| RIGHT EYE | 35 |  | Ferocious bolt of plasma tears through the [target]'s eye and fries the brain! | Ferocious bolt of plasma tears |
| RIGHT EYE | 40 | F | The [target]'s eye is melted into a bloody mess by a stunning bolt of plasma! | eye is melted into a bloody mess by a stunning bolt of plasma |
| RIGHT EYE | 45 | F | Explosive blast sears the [target]'s eye away along with most of the face! | eye away along with most of the face |
| RIGHT EYE | 50 | F | The [target]'s eye bubbles and bursts along with most of the head! | eye bubbles and bursts along with most of the head |
| LEFT EYE | 0 |  | The <target> blinks away tears from a brilliant flash of light. | The <target> blinks away tears from a brilliant flash of light |
| LEFT EYE | 5 (1) |  | Flash burns to eye momentarily blind the [target]. | Flash burns to eye momentarily blind |
| LEFT EYE | 10 (6) |  | Intense blast to the [target]'s eyelid causes it to sizzle and pop. | eyelid causes it to sizzle and pop |
| LEFT EYE | 15 (14) |  | Blistering bolt of energy causes the [target]'s eyelid to burn to a crisp! | Blistering bolt of energy causes |
| LEFT EYE | 20 (30) |  | The [target]'s eye blackens and pops leaving a smoking hole behind! | eye blackens and pops leaving a smoking hole behind |
| LEFT EYE | 25 (30) |  | The [target]'s eye is blown out of socket by powerful bolt of plasma! | eye is blown out of socket by powerful bolt of plasma |
| LEFT EYE | 35 |  | Ferocious bolt of plasma tears through the [target]'s eye and fries the brain! | Ferocious bolt of plasma tears |
| LEFT EYE | 40 | F | The [target]'s eye is melted into a bloody mess by a stunning bolt of plasma! | eye is melted into a bloody mess by a stunning bolt of plasma |
| LEFT EYE | 45 | F | Explosive blast sears the [target]'s eye away along with most of the face! | eye away along with most of the face |
| LEFT EYE | 50 | F | The [target]'s eye bubbles and bursts along with most of the head! | eye bubbles and bursts along with most of the head |
| CHEST | 0 |  | A blast of hot air pushes the [target] back a step. | A blast of hot air pushes |
| CHEST | 5 |  | Pinpoint strike sears the [target]'s chest. | Pinpoint strike sears the |
| CHEST | 10 (5) |  | Searing bolt of energy strikes the [target], scorching a wide swath of flesh! | scorching a wide swath of flesh |
| CHEST | 15 |  | Dazzling arc of energy traces blackened path across the [target]'s chest! | Dazzling arc of energy traces blackened path across |
| CHEST | 25 |  | Glaring burst to the [target]'s chest dances across skin leaving smoking holes! | chest dances across skin leaving smoking holes |
| CHEST | 25 |  | A raw, red hole is drilled in the [target]'s chest by a powerful bolt! The [target] falls to the ground motionless. | falls to the ground motionless |
| CHEST | 45 |  | Tremendous plasma discharge slices deep into the [target]'s chest! | Tremendous plasma discharge slices deep |
| CHEST | 50 | F | The [target] is sliced open neatly by a brilliant beam of plasma! | is sliced open neatly by a brilliant beam of plasma |
| CHEST | 60 | F | The [target]'s lungs superheat forcing plasma up through nose and mouth! | lungs superheat forcing plasma up through nose and mouth |
| CHEST | 75 | F | Explosive burst wreathes the [target]'s body in blue flames! | Explosive burst wreathes |
| ABDOMEN | 0 |  | Plasma burst to stomach gives [target] a bad case of indigestion. | a bad case of indigestion |
| ABDOMEN | 5 |  | Plasma scalds the [target]'s stomach leaving painful red streaks. | stomach leaving painful red streaks |
| ABDOMEN | 10 |  | A curling tongue of blue flame sears the skin on the [target]'s stomach. | A curling tongue of blue flame sears the skin |
| ABDOMEN | 15 |  | Superheated arc of plasma traces blackened path across the [target]'s belly! | Superheated arc of plasma traces blackened path across |
| ABDOMEN | 20 (15) |  | Skin blasted away leaving exposed and bloody muscle! | Skin blasted away leaving exposed and bloody muscle |
| ABDOMEN | 25 |  | Muscle and blood explode from the [target]'s abdomen in a steaming spray! | abdomen in a steaming spray |
| ABDOMEN | 30 |  | Powerful blast to the [target]'s abdomen parboils internal organs! | abdomen parboils internal organs |
| ABDOMEN | 50 |  | The [target] is sliced open neatly by a brilliant beam of plasma! | is sliced open neatly by a brilliant beam of plasma |
| ABDOMEN | 60 | F | Internal organs roasted instantly in an explosive flash of plasma! | Internal organs roasted instantly in an explosive flash of plasma |
| ABDOMEN | 75 | F | Internal organs boil and explode in a bloody spray! | Internal organs boil and explode in a bloody spray |
| BACK | 0 |  | Blast of heat to the [target]'s back causes muscle spasms. | back causes muscle spasms |
| BACK | 5 |  | Searing strike to back causes the [target] to grunt in pain. | to grunt in pain |
| BACK | 10 (6) |  | Powerful burst to the [target]'s back causes excruciating pain. | back causes excruciating pain |
| BACK | 15 (10) |  | Dazzling arc of energy traces blackened path across the [target]'s back! | Dazzling arc of energy traces blackened path across |
| BACK | 20 (30) |  | Skin and muscle roasted away leaving the ribs exposed on the [target]'s back! | Skin and muscle roasted away leaving the ribs exposed |
| BACK | 25 |  | Skin roasted away from back exposing the [target]'s spinal column! | spinal column |
| BACK | 30 |  | Vicious beam of energy rips open the [target]'s back! | Vicious beam of energy rips open |
| BACK | 50 |  | Whiplike blast of plasma creates a gaping hole in the [target]'s lower back! | Whiplike blast of plasma creates a gaping hole |
| BACK | 60 | F | Explosive burst wreathes the [target]'s back in shimmering blue flames! | back in shimmering blue flames |
| BACK | 75 | F | The [target]'s skeletal structure and muscle tissue reduced to fine ash! | skeletal structure and muscle tissue reduced to fine ash |
| RIGHT ARM | 0 |  | The [target]'s weapon arm is seriously tanned. | weapon arm is seriously tanned |
| RIGHT ARM | 5 |  | Plasma lashes the [target]'s weapon arm blistering flesh. | weapon arm blistering flesh |
| RIGHT ARM | 10 (5) |  | Minor burns to the [target]'s weapon arm. |  |
| RIGHT ARM | 15 (10) |  | Plasma scorches a hole in the [target]'s weapon arm! | Plasma scorches a hole |
| RIGHT ARM | 20 (15) |  | Intense arc of energy flays the [target]'s arm to the bone! | Intense arc of energy flays |
| RIGHT ARM | 25 (15) |  | Intense beam of plasma shears away large chunks of the [target]'s forearm! | Intense beam of plasma shears away large chunks |
| RIGHT ARM | 30 (20) |  | Muscle blasted away from the [target]'s arm exposing scorched bone! | arm exposing scorched bone |
| RIGHT ARM | 35 (25) |  | Awesome lash of plasma severs the [target]'s arm completely! | Awesome lash of plasma severs |
| RIGHT ARM | 40 (35) |  | The [target]'s arm shatters and explodes from a tremendous surge of plasma! | arm shatters and explodes from a tremendous surge of plasma |
| RIGHT ARM | 45 (40) |  | Muscle and bone blasted to pieces by searing wave of energy! | Muscle and bone blasted to pieces by searing wave of energy |
| LEFT ARM | 0 |  | The [target]'s shield arm is seriously tanned. | shield arm is seriously tanned |
| LEFT ARM | 5 |  | Plasma lashes the [target]'s shield arm blistering flesh. | shield arm blistering flesh |
| LEFT ARM | 10 (5) |  | Minor burns to the [target]'s shield arm. |  |
| LEFT ARM | 15 (10) |  | Plasma scorches a hole in the [target]'s shield arm! | Plasma scorches a hole |
| LEFT ARM | 20 (15) |  | Intense arc of energy flays the [target]'s arm to the bone! | Intense arc of energy flays |
| LEFT ARM | 25 (15) |  | Intense beam of plasma shears away large chunks of the [target]'s forearm! | Intense beam of plasma shears away large chunks |
| LEFT ARM | 30 (20) |  | Muscle blasted away from the [target]'s arm exposing scorched bone! | arm exposing scorched bone |
| LEFT ARM | 35 (25) |  | Awesome lash of plasma severs the [target]'s arm completely! | Awesome lash of plasma severs |
| LEFT ARM | 40 (35) |  | The [target]'s arm shatters and explodes from a tremendous surge of plasma! | arm shatters and explodes from a tremendous surge of plasma |
| LEFT ARM | 45 (40) |  | Muscle and bone blasted to pieces by searing wave of energy! | Muscle and bone blasted to pieces by searing wave of energy |
| RIGHT HAND | 0 |  | The [target]'s sweaty palm is quick-dried by the heat! | sweaty palm is quick-dried by the heat |
| RIGHT HAND | 5 (1) |  | Stinging burn to the [target]'s hand. | Stinging burn |
| RIGHT HAND | 10 (5) |  | The [target]'s hand is encased in shimmering blue flames! | hand is encased in shimmering blue flames |
| RIGHT HAND | 15 (5) |  | The [target]'s hand blisters and bleeds from intense heat. | hand blisters and bleeds from intense heat |
| RIGHT HAND | 20 (15) |  | Vicious hole burned through the [target]'s weapon hand! | Vicious hole burned through |
| RIGHT HAND | 25 (8) |  | The [target]'s fingers burn and explode leaving blackened stumps! | fingers burn and explode leaving blackened stumps |
| RIGHT HAND | 30 (10) |  | Scorching blast causes the bones in the [target]'s hand to expand and burst. | Scorching blast causes the bones |
| RIGHT HAND | 35 (15) |  | Immolating blast causes the [target]'s hand to explode. | Immolating blast causes the |
| RIGHT HAND | 40 (25) |  | Encasing plasma cremates the [target]'s hand leaving a bloody stump! | hand leaving a bloody stump |
| RIGHT HAND | 45 (30) |  | Muscle and bone blasted to pieces by powerful bolt of energy! | Muscle and bone blasted to pieces by powerful bolt of energy |
| LEFT HAND | 0 |  | The [target]'s sweaty palm is quick-dried by the heat! | sweaty palm is quick-dried by the heat |
| LEFT HAND | 5 (1) |  | Stinging burn to the [target]'s hand. | Stinging burn |
| LEFT HAND | 10 (5) |  | The [target]'s hand is encased in shimmering blue flames! | hand is encased in shimmering blue flames |
| LEFT HAND | 15 (5) |  | The [target]'s hand blisters and bleeds from intense heat. | hand blisters and bleeds from intense heat |
| LEFT HAND | 20 (15) |  | Vicious hole burned through the [target]'s shield hand! | Vicious hole burned through |
| LEFT HAND | 25 (8) |  | The [target]'s fingers burn and explode leaving blackened stumps! | fingers burn and explode leaving blackened stumps |
| LEFT HAND | 30 (10) |  | Scorching blast causes the bones in the [target]'s hand to expand and burst. | Scorching blast causes the bones |
| LEFT HAND | 35 (15) |  | Immolating blast causes the [target]'s hand to explode. | Immolating blast causes the |
| LEFT HAND | 40 (25) |  | Encasing plasma cremates the [target]'s hand leaving a bloody stump! | hand leaving a bloody stump |
| LEFT HAND | 45 (30) |  | Muscle and bone blasted to pieces by powerful bolt of energy! | Muscle and bone blasted to pieces by powerful bolt of energy |
| RIGHT LEG | 0 |  | The [target]'s leg hair is singed off, smooth shave! | leg hair is singed off, smooth shave |
| RIGHT LEG | 5 (7) |  | Light burns to the [target]'s leg. |  |
| RIGHT LEG | 10 (5) |  | Blistering strike to leg shrivels skin and causes excruciating pain. | Blistering strike to leg shrivels skin and causes excruciating pain |
| RIGHT LEG | 15 (10) |  | Searing blast of energy to hip spins the [target] around! | Searing blast of energy to hip spins |
| RIGHT LEG | 20 (15) |  | Searing wave of plasma cuts through skin and muscle on the [target]'s leg! | Searing wave of plasma cuts through skin and muscle |
| RIGHT LEG | 25 (20) |  | Superheated energy causes the artery in the [target]'s leg to explode! | Superheated energy causes the artery |
| RIGHT LEG | 30 (25) |  | Sizzling arc of plasma blows the [target]'s kneecap off! | Sizzling arc of plasma blows |
| RIGHT LEG | 35 (30) |  | Fiery blast of plasma blows the [target]'s leg into a bloody spray! | Fiery blast of plasma blows |
| RIGHT LEG | 40 |  | The [target]'s leg is consumed in an intense field of plasma reducing it to ash! | leg is consumed in an intense field of plasma reducing it to ash |
| RIGHT LEG | 45 |  | Muscle and bone blasted to pieces by searing wave of energy! | Muscle and bone blasted to pieces by searing wave of energy |
| LEFT LEG | 0 |  | The [target]'s leg hair is singed off, smooth shave! | leg hair is singed off, smooth shave |
| LEFT LEG | 5 (7) |  | Light burns to the [target]'s leg. |  |
| LEFT LEG | 10 (5) |  | Blistering strike to leg shrivels skin and causes excruciating pain. | Blistering strike to leg shrivels skin and causes excruciating pain |
| LEFT LEG | 15 (10) |  | Searing blast of energy to hip spins the [target] around! | Searing blast of energy to hip spins |
| LEFT LEG | 20 (15) |  | Searing wave of plasma cuts through skin and muscle on the [target]'s leg! | Searing wave of plasma cuts through skin and muscle |
| LEFT LEG | 25 (20) |  | Superheated energy causes the artery in the [target]'s leg to explode! | Superheated energy causes the artery |
| LEFT LEG | 30 (25) |  | Sizzling arc of plasma blows the [target]'s kneecap off! | Sizzling arc of plasma blows |
| LEFT LEG | 35 (30) |  | Fiery blast of plasma blows the [target]'s leg into a bloody spray! | Fiery blast of plasma blows |
| LEFT LEG | 40 |  | The [target]'s leg is consumed in an intense field of plasma reducing it to ash! | leg is consumed in an intense field of plasma reducing it to ash |
| LEFT LEG | 45 (30) |  | Muscle and bone blasted to pieces by searing wave of energy! | Muscle and bone blasted to pieces by searing wave of energy |

## Puncture  (130 messages, 26 fatal)

| sec | rank | F | message | current match |
|---|---|---|---|---|
| Head | 0 |  | Thrust catches chin.  Leaves an impression but no cut. | Leaves an impression but no cut |
| Head | 5 |  | Glancing strike to the head! | Glancing strike to the head |
| Head | 8 |  | Nice shot to the head gouges the [target]'s cheek! | Nice shot to the head gouges |
| Head | 10 |  | Beautiful head shot!  That ear will be missed! | That ear will be missed |
| Head | 15 |  | Strike to temple!  Saved by thick skull! | Saved by thick skull |
| Head | 20 |  | Beautiful shot pierces skull!  Amazing the [target] wasn't killed outright! | Beautiful shot pierces skull |
| Head | 25 | F | Amazing shot through the [target]'s nose enters the brain! | nose enters the brain |
| Head | 30 | F | Strike through both ears, foe is quite dead! | Strike through both ears, foe is quite dead |
| Head | 35 | F | Strike pierces temple and kills foe instantly! | Strike pierces temple and kills foe instantly |
| Head | 40 | F | Awesome shot skewers skull!  The [target] blinks once and falls quite dead! | blinks once and falls quite dead |
| Neck | 0 |  | Talk about a close shave!  Let's try closer next time. | Let's try closer next time |
| Neck | 3 |  | Minor strike to neck. | Minor strike to neck |
| Neck | 5 |  | Well placed shot to the neck. | Well placed shot to the neck |
| Neck | 7 |  | Strike just below the jaw, nice shot to the neck! | Strike just below the jaw, nice shot to the neck |
| Neck | 10 |  | Pierced through neck, a fine shot! | Pierced through neck, a fine shot |
| Neck | 15 |  | Neck skewered, sliding past the throat and spine!  That looks painful. | Neck skewered, sliding past the throat and spine |
| Neck | 15 | F | Fine shot pierces jugular vein!  The brain wonders where all its oxygen went, briefly. | The brain wonders where all its oxygen went, briefly |
| Neck | 20 | F | Strike clean through neck, what a shot!  Good form! | Strike clean through neck, what a shot!  Good form |
| Neck | 25 | F | Strike punctures throat and ruins vocal cords! | Strike punctures throat and ruins vocal cords |
| Neck | 30 | F | Incredible shot clean through the throat severs the spine! | Incredible shot clean through the throat severs the spine |
| Right Eye | 0 |  | Attack bumps an eyebrow.  Oh!  So close! | Attack bumps an eyebrow |
| Right Eye | 1 |  | Minor strike under the right  eye, that was close! | eye, that was close |
| Right Eye | 5 |  | Well aimed shot almost removes an eye! | Well aimed shot almost removes an eye |
| Right Eye | 10 |  | Slash across right eye! Hope the left is working. | Hope the left is working |
| Right Eye | 17 | F | Attack punctures the eye and connects with something really vital! | Attack punctures the eye and connects with something really vital |
| Right Eye | 20 | F | Shot knocks the [target]'s head back by pushing on the inside of the skull! | head back by pushing on the inside of the skull |
| Right Eye | 25 | F | Incredible shot to the eye penetrates deep into skull! | Incredible shot to the eye penetrates deep into skull |
| Right Eye | 30 | F | Shot destroys eye and the brain behind it! | Shot destroys eye and the brain behind it |
| Right Eye | 35 | F | Strike through eye, the [target] is lobotomized! | is lobotomized |
| Right Eye | 40 | F | Strike to the eye penetrates skull, ocular fluid sprays widely! | Strike to the eye penetrates skull, ocular fluid sprays widely |
| Left Eye | 0 |  | Attack bumps an eyebrow.  Oh!  So close! | Attack bumps an eyebrow |
| Left Eye | 1 |  | Minor strike under the left eye, that was close! | eye, that was close |
| Left Eye | 5 |  | Well aimed shot almost removes an eye! | Well aimed shot almost removes an eye |
| Left Eye | 10 |  | Surgical strike removes the [target]'s left eye! | Surgical strike removes the |
| Left Eye | 17 | F | Attack punctures the eye and connects with something really vital! | Attack punctures the eye and connects with something really vital |
| Left Eye | 20 | F | Shot knocks the [target]'s head back by pushing on the inside of the skull! | head back by pushing on the inside of the skull |
| Left Eye | 25 | F | Incredible shot to the eye penetrates deep into skull! | Incredible shot to the eye penetrates deep into skull |
| Left Eye | 30 | F | Shot destroys eye and the brain behind it! | Shot destroys eye and the brain behind it |
| Left Eye | 35 | F | Strike through eye, the [target] is lobotomized! | is lobotomized |
| Left Eye | 40 | F | Strike to the eye penetrates skull, ocular fluid sprays widely! | Strike to the eye penetrates skull, ocular fluid sprays widely |
| Chest | 0 |  | Blow slides along ribs.  Probably tickles. | Blow slides along ribs |
| Chest | 5 |  | Minor puncture to the chest. | Minor puncture to the chest |
| Chest | 10 |  | Strike to the chest breaks a rib! | Strike to the chest breaks a rib |
| Chest | 15 |  | Loud *crack* as the [target]'s sternum breaks! | sternum breaks |
| Chest | 20 |  | Well placed strike shatters a rib! | Well placed strike shatters a rib |
| Chest | 25 |  | Damaging strike to chest, several ribs shattered! | Damaging strike to chest, several ribs shattered |
| Chest | 30 |  | Strong strike, punctures lung! | Strong strike, punctures lung |
| Chest | 35 |  | Awesome shot shatters ribs and punctures lung! | Awesome shot shatters ribs and punctures lung |
| Chest | 40 | F | Beautiful shot pierces both lungs, the [target] makes a wheezing noise, and drops dead! | makes a wheezing noise, and drops dead |
| Chest | 50 | F | Incredible strike pierces heart and runs the [target] clean through! | Incredible strike pierces heart and runs |
| Abdomen | 0 |  | Poked in the tummy.  Hehehe. | Poked in the tummy |
| Abdomen | 5 |  | Minor puncture to abdomen. | Minor puncture to abdomen |
| Abdomen | 10 |  | Nice puncture to the abdomen, just missed vital organs! | Nice puncture to the abdomen, just missed vital organs |
| Abdomen | 15 |  | Strike pierces gall bladder!  That's gotta hurt! | Strike pierces gall bladder |
| Abdomen | 20 |  | Strike to abdomen punctures stomach! | Strike to abdomen punctures stomach |
| Abdomen | 25 |  | Vicious strike punctures intestines! | Vicious strike punctures intestines |
| Abdomen | 30 |  | Deft strike to abdomen penetrates several useful organs! | Deft strike to abdomen penetrates several useful organs |
| Abdomen | 35 |  | Bladder impaled, what a mess! | Bladder impaled, what a mess |
| Abdomen | 40 | F | Strike to abdomen skewers the [target] quite nicely! | quite nicely |
| Abdomen | 50 | F | Perfect strike to abdomen.  The [target] howls in pain and drops quite dead! | howls in pain and drops quite dead |
| Back | 0 |  | Thrust slides along the back.  Cuts a nagging itch. | Thrust slides along the back |
| Back | 5 |  | Minor puncture to the back. | Minor puncture to the back |
| Back | 10 |  | Nice puncture to the back, just grazed the spine! | Nice puncture to the back, just grazed the spine |
| Back | 15 |  | Strike connects with shoulder blade! | Strike connects with shoulder blade |
| Back | 20 |  | Nailed in lower back! | Nailed in lower back |
| Back | 25 |  | Well placed strike to back shatters vertebrae! | Well placed strike to back shatters vertebrae |
| Back | 30 |  | Deft strike to the back cracks vertebrae! | Deft strike to the back cracks vertebrae |
| Back | 35 |  | Awesome shot shatters spine and punctures lung! | Awesome shot shatters spine and punctures lung |
| Back | 40 | F | Shot to back shatters bone and vertebrae! | Shot to back shatters bone and vertebrae |
| Back | 50 | F | Incredible shot impales a kidney.  Too painful to even scream. | Incredible shot impales a kidney.  Too painful to even scream |
| Right Arm | 0 |  | Tap to the arm pricks some interest but not much else. | Tap to the arm pricks some interest but not much else |
| Right Arm | 3 |  | Minor puncture to the right arm. | Minor puncture to the right arm |
| Right Arm | 5 |  | Strike pierces upper arm! | Strike pierces upper arm |
| Right Arm | 7 |  | Well aimed shot, punctures upper arm! | Well aimed shot, punctures upper arm |
| Right Arm | 10 |  | Strike pierces forearm! | Strike pierces forearm |
| Right Arm | 14 |  | Elbow punctured, oh what pain! | Elbow punctured, oh what pain |
| Right Arm | 17 |  | Well aimed strike shatters bone in right arm! | Well aimed strike shatters bone in right arm |
| Right Arm | 22 |  | Strike to right arm cleanly severs it at the shoulder! | arm cleanly severs it at the shoulder |
| Right Arm | 25 |  | Strike to right arm shatters elbow and severs forearm! | arm shatters elbow and severs forearm |
| Right Arm | 25 |  | Shot shatters shoulder and severs right arm! | Shot shatters shoulder and severs right arm |
| Left Arm | 0 |  | Tap to the arm pricks some interest but not much else. | Tap to the arm pricks some interest but not much else |
| Left Arm | 3 |  | Minor puncture to the left arm. | Minor puncture to the left arm |
| Left Arm | 5 |  | Strike pierces upper arm! | Strike pierces upper arm |
| Left Arm | 7 |  | Well aimed shot, punctures upper arm! | Well aimed shot, punctures upper arm |
| Left Arm | 10 |  | Strike pierces forearm! | Strike pierces forearm |
| Left Arm | 14 |  | Elbow punctured, oh what pain! | Elbow punctured, oh what pain |
| Left Arm | 17 |  | Well aimed strike shatters bone in left arm! | Well aimed strike shatters bone in left arm |
| Left Arm | 22 |  | Strike to left arm cleanly severs it at the shoulder! | arm cleanly severs it at the shoulder |
| Left Arm | 25 |  | Strike to left arm shatters elbow and severs forearm! | arm shatters elbow and severs forearm |
| Left Arm | 25 |  | Shot shatters shoulder and severs left arm! | Shot shatters shoulder and severs left arm |
| Right Hand | 0 |  | Strikes a fingernail.  Bet it'll lose it now. | Bet it'll lose it now |
| Right Hand | 1 |  | Strike to right hand breaks a fingernail! | hand breaks a fingernail |
| Right Hand | 3 |  | Strike through the palm! | Strike through the palm |
| Right Hand | 5 |  | Shot to the hand slices a finger to the bone! | Shot to the hand slices a finger to the bone |
| Right Hand | 7 |  | Shot pierces a wrist! | Shot pierces a wrist |
| Right Hand | 9 |  | Slash across back of hand, tendons sliced! | Slash across back of hand, tendons sliced |
| Right Hand | 12 |  | Impressive shot shatters wrist! | Impressive shot shatters wrist |
| Right Hand | 15 |  | Strike to wrist severs right hand! | Strike to wrist severs right hand |
| Right Hand | 18 |  | Strike to wrist severs right hand! | Strike to wrist severs right hand |
| Right Hand | 20 |  | Strike to wrist severs right hand quite neatly! | Strike to wrist severs right hand |
| Left Hand | 0 |  | Strikes a fingernail.  Bet it'll lose it now. | Bet it'll lose it now |
| Left Hand | 1 |  | Strike to left hand breaks a fingernail! | hand breaks a fingernail |
| Left Hand | 3 |  | Strike through the palm! | Strike through the palm |
| Left Hand | 5 |  | Shot to the hand slices a finger to the bone! | Shot to the hand slices a finger to the bone |
| Left Hand | 7 |  | Shot pierces a wrist! | Shot pierces a wrist |
| Left Hand | 9 |  | Slash across back of hand, tendons sliced! | Slash across back of hand, tendons sliced |
| Left Hand | 12 |  | Impressive shot shatters wrist! | Impressive shot shatters wrist |
| Left Hand | 15 |  | Strike to wrist severs left hand! | Strike to wrist severs left hand |
| Left Hand | 18 |  | Strike to wrist severs left hand! | Strike to wrist severs left hand |
| Left Hand | 20 |  | Strike to wrist severs left hand quite neatly! | Strike to wrist severs left hand |
| Right Leg | 0 |  | Thrust glances off the [target]'s knee without a lot of effect. | knee without a lot of effect |
| Right Leg | 5 |  | Minor puncture to the right leg. | Minor puncture to the right leg |
| Right Leg | 9 |  | Strike pierces thigh! | Strike pierces thigh |
| Right Leg | 13 |  | Well aimed shot, punctures calf! | Well aimed shot, punctures calf |
| Right Leg | 17 |  | Strike pierces calf! | Strike pierces calf |
| Right Leg | 20 |  | Well placed shot pierces knee, that hurt! | Well placed shot pierces knee, that hurt |
| Right Leg | 23 |  | Great shot penetrates thigh and shatters bone! | Great shot penetrates thigh and shatters bone |
| Right Leg | 27 |  | Blow shatters knee and severs lower leg! | Blow shatters knee and severs lower leg |
| Right Leg | 30 |  | Strike punctures thigh and shatters femur! | Strike punctures thigh and shatters femur |
| Right Leg | 35 |  | Shot shatters hip and severs right leg! | Shot shatters hip and severs right leg |
| Left Leg | 0 |  | Thrust glances off the [target]'s knee without a lot of effect. | knee without a lot of effect |
| Left Leg | 5 |  | Minor puncture to the left leg. | Minor puncture to the left leg |
| Left Leg | 9 |  | Strike pierces thigh! | Strike pierces thigh |
| Left Leg | 13 |  | Well aimed shot, punctures calf! | Well aimed shot, punctures calf |
| Left Leg | 17 |  | Strike pierces calf! | Strike pierces calf |
| Left Leg | 20 |  | Well placed shot pierces knee, that hurt! | Well placed shot pierces knee, that hurt |
| Left Leg | 23 |  | Great shot penetrates thigh and shatters bone! | Great shot penetrates thigh and shatters bone |
| Left Leg | 27 |  | Blow shatters knee and severs lower leg! | Blow shatters knee and severs lower leg |
| Left Leg | 30 |  | Strike punctures thigh and shatters femur! | Strike punctures thigh and shatters femur |
| Left Leg | 35 |  | Shot shatters hip and severs left leg! | Shot shatters hip and severs left leg |

## Slash  (130 messages, 24 fatal)

| sec | rank | F | message | current match |
|---|---|---|---|---|
| HEAD | 0 |  | Flashy swing!  Too bad it only bopped the [target]'s nose. | Too bad it only bopped |
| HEAD | 5 |  | Quick slash catches the [target]'s cheek!  Dimples are always nice. | Dimples are always nice |
| HEAD | 10 |  | Blade slashes across the [target]'s face!  Nice nose job. | Blade slashes across the |
| HEAD | 15 |  | Blow to head! | Blow to head |
| HEAD | 20 |  | Quick flick of the wrist!  The [target] is slashed across its forehead! | is slashed across its forehead |
| HEAD | 25 |  | Hard blow to the [target's] ear!  Deep gash and a terrible headache! | Deep gash and a terrible headache |
| HEAD | 30 | F | Gruesome slash opens the [target]'s forehead!  Grey matter spills forth! | Grey matter spills forth |
| HEAD | 35 | F | Wild upward slash remove the [target]'s face from its skull! Interesting way to die. | Wild upward slash remove |
| HEAD | 40 | F | Horrible slash to the [target]'s head!  Brain matter goes flying! Looks like it never felt a thing. | Looks like it never felt a thing |
| HEAD | 50 | F | Gruesome, slashing blow to the side of the [target]'s head!  Skull split open!  Brain (and life) vanishes in a fine mist. | Brain (and life) vanishes in a fine mist |
| NECK | 0 |  | Close shave!  The [target] takes a quick step back. | takes a quick step back |
| NECK | 2 |  | Attack hits the [target]'s throat but doesn't break the skin.  Close! | throat but doesn't break the skin |
| NECK | 5 |  | Strike dents the [target]'s larynx.  Swallowing will be fun. | Swallowing will be fun |
| NECK | 10 |  | Deft swing strikes the [target]'s neck.  Maybe not fatal but it's sure distracting. | Maybe not fatal but it's sure distracting |
| NECK | 12 |  | Strong slash to throat nicks a few blood vessels. | Strong slash to throat nicks a few blood vessels |
| NECK | 15 |  | Fast slash to the [target]'s neck exposes its windpipe.  Quick anatomy lesson, anyone? | Quick anatomy lesson, anyone |
| NECK | 20 | F | Deep slash to the [target]'s neck severs an artery!  The [target] chokes to death on its own blood. | chokes to death on its own blood |
| NECK | 25 | F | Gruesome slash to the [target]'s throat! That stings... for about a second. | for about a second |
| NECK | 30 | F | Awful slash nearly decapitates the [target]!  That's one way to lose your head. | That's one way to lose your head |
| NECK | 40 | F | Incredible slash to the [target]'s neck!  Throat and vocal cords destroyed! Zero chance of survival. | Throat and vocal cords destroyed |
| RIGHT EYE | 0 |  | Quick slash at the [target]'s right eye.  Strike lands but misses target. | Strike lands but misses target |
| RIGHT EYE | 3 |  | Slashing strike near forehead nicks an eyebrow!  That must sting! | Slashing strike near forehead nicks an eyebrow |
| RIGHT EYE | 3 |  | Gash to the [target]'s right eyebrow.  That's going to be quite a shiner! | That's going to be quite a shiner |
| RIGHT EYE | 5 |  | Grazing slash to the [target]'s face!  Scratch to its eyelids.  "When blood gets in your eyes..." | When blood gets in your eyes |
| RIGHT EYE | 20 |  | Upward slash gouges the [target]'s cheek!  Right eye lost!  Pity. | Upward slash gouges the |
| RIGHT EYE | 25 | F | Slash strikes the [target]'s right eye.  Seems there was a brain there   after all. | Seems there was a brain there   after all |
| RIGHT EYE | 30 | F | Slash to head destroys the [target]'s right eye!  Doesn't do its brain any good either. | Doesn't do its brain any good either |
| RIGHT EYE | 40 | F | Slash to the [target]'s right eye!  Vitreous fluid spews forth!  Seeya! | Vitreous fluid spews forth |
| RIGHT EYE | 45 | F | Horrifying slash to the [target]'s head!  Right eye sliced open!  Brain pureed! | Right eye sliced open |
| RIGHT EYE | 50 | F | Blast to the [target]'s head destroys right eye!  Brain obliterated! Disgusting, but painful only for a second. | Disgusting, but painful only for a second |
| LEFT EYE | 0 |  | Quick slash to the [target]'s left eye.  Strike lands but misses target. | Strike lands but misses target |
| LEFT EYE | 3 |  | Slashing strike near forehead nicks an eyelid!  That must sting! | Slashing strike near forehead nicks an eyelid |
| LEFT EYE | 3 |  | Gash to the [target]'s left eyebrow.  That's going to be quite a shiner! | That's going to be quite a shiner |
| LEFT EYE | 5 |  | Grazing slash to the [target]'s face!  Scratches its left eye.  Ouch! | Grazing slash |
| LEFT EYE | 20 |  | Upward slash gouges the [target]'s cheek!  Left eye lost!  Pity. | Upward slash gouges the |
| LEFT EYE | 25 | F | Slash strikes the [target]'s left eye.  Seems there was a brain there   after all. | Seems there was a brain there   after all |
| LEFT EYE | 30 | F | Slash to head destroys the [target]'s left eye!  Doesn't do its brain any good either. | Doesn't do its brain any good either |
| LEFT EYE | 40 | F | Slash to the [target]'s left eye!  Vitreous fluid spews forth!  Seeya! | Vitreous fluid spews forth |
| LEFT EYE | 45 | F | Horrifying slash to the [target]'s head!  Left eye sliced open!  Brain  pureed! | Left eye sliced open |
| LEFT EYE | 50 | F | Blast to the [target]'s head destroys left eye!  Brain obliterated!    Disgusting, but painful only for a second. | Disgusting, but painful only for a second |
| CHEST | 0 |  | Weak slash across chest!  Slightly less painful than heartburn. | Slightly less painful than heartburn |
| CHEST | 1 |  | Deft slash across chest draws blood!  The [target] takes a deep breath. | takes a deep breath |
| CHEST | 10 |  | Slash to the [target]'s chest!  That heart's not broken, it's only scratched. | That heart's not broken, it's only scratched |
| CHEST | 15 |  | Slash to [target]'s chest.  Breathe deep, it'll feel better in a minute. | Breathe deep, it'll feel better in a minute |
| CHEST | 20 |  | Slashing blow to chest knocks the [target] back a few paces! | blow to chest knocks |
| CHEST | 25 |  | Crossing slash to the chest catches the [target]'s attention! | Crossing slash to the chest catches |
| CHEST | 45 |  | Hard slash to the [target]'s side opens its spleen! | side opens its spleen |
| CHEST | 60 |  | Quick, powerful slash!  The [target]'s chest is ripped open! | Quick, powerful slash |
| CHEST | 65 | F | Slash to the [target]'s ribs opens a sucking chest wound! | ribs opens a sucking chest wound |
| CHEST | 70 | F | Wicked slash slices open the [target]'s chest!  Heart and lung pureed! Sickening! | Wicked slash slices open |
| ABDOMEN | 0 |  | Light slash to the [target]'s abdomen!  Barely nicked. | Barely nicked |
| ABDOMEN | 5 |  | Awkward slash to the [target]'s stomach!  Everyone needs another belly button. | Everyone needs another belly button |
| ABDOMEN | 10 |  | Smooth slash to the [target]'s hip!  Nice crunching sound. | Nice crunching sound |
| ABDOMEN | 15 |  | Hard slash to belly severs a few nerve endings. | Hard slash to belly severs a few nerve endings |
| ABDOMEN | 20 |  | Diagonal slash leaves a bloody trail across the [target]'s torso. | Diagonal slash leaves a bloody trail across |
| ABDOMEN | 25 |  | The [target] is backed up by a strong slash to its abdomen! | is backed up by a strong slash to its abdomen |
| ABDOMEN | 30 |  | Deep slash to the [target]'s right side!  Several inches of padding   sliced off hip....  From the inside! | From the inside |
| ABDOMEN | 50 |  | Amazing slash to the [target]'s belly!  Nothing quite like that empty feeling inside. | Nothing quite like that empty feeling inside |
| ABDOMEN | 60 | F | Bloody slash to the [target]'s side!  Instant death, due to lack of   intestines. | Bloody slash |
| ABDOMEN | 75 | F | Terrible slash to the [target]'s side!  Entrails spill out, onto the  ground!  Death can be SO messy. | Entrails spill out, onto the  ground |
| BACK | 0 |  | Glancing blow to the [target]'s back.  That could have been better. | That could have been better |
| BACK | 3 |  | Weak slash to the [target]'s lower back! |  |
| BACK | 10 |  | Feint to the left goes astray as the [target] dodges!  You scratch my back... | You scratch my back |
| BACK | 15 |  | Slash along the [target]'s lower back. |  |
| BACK | 20 |  | Slash to the [target]'s lower back! Pain shoots up along [target]'s spine. | Pain shoots up along |
| BACK | 25 |  | Feint left spins the [target] around!  Jagged slash to lower back. | Jagged slash to lower back |
| BACK | 30 |  | The [target] twists away but is caught with a hard slash!  Back is broken! | twists away but is caught with a hard slash |
| BACK | 50 |  | Deft slash!  The [target] is spun around and hit hard in its lower back. | is spun around and hit hard in its lower back |
| BACK | 60 | F | Slash to the [target]'s lower back!  Kidneys sliced and diced!  Death is slow and painful. | Death is slow and painful |
| BACK | 75 | F | Masterful slash to the [target]'s lower back!  Spinal cord and life are just memories now. | Spinal cord and life are just memories now |
| RIGHT ARM | 0 |  | Weak slash to the [target]'s right arm.  That doesn't even sting. | That doesn't even sting |
| RIGHT ARM | 3 |  | Quick slash to the [target]'s upper right arm!  Just a nick. |  |
| RIGHT ARM | 7 |  | Hesitant slash to the [target]'s upper right arm!  Just a scratch. | Hesitant slash |
| RIGHT ARM | 8 |  | Slash to the [target]'s right arm!  Slices neatly through the skin and  meets bone! | Slices neatly through the skin and  meets bone |
| RIGHT ARM | 10 |  | Powerful slash just cracks the [target]'s weapon arm! | Powerful slash just cracks |
| RIGHT ARM | 15 |  | Deep slash to the [target]'s right forearm! |  |
| RIGHT ARM | 20 |  | Quick, hard slash to the [target]'s right arm!  "CRACK" | Quick, hard slash to |
| RIGHT ARM | 25 |  | Hard slash to the [target]'s side!  Right arm no longer available for   use. | arm no longer available for   use |
| RIGHT ARM | 35 |  | Spectacular slash!  The [target]'s right arm is neatly amputated! | arm is neatly amputated |
| RIGHT ARM | 40 |  | Awesome slash sever the [target]'s right arm!  A jagged stump is all that remains! | A jagged stump is all that remains |
| LEFT ARM | 0 |  | Hard blow, but deflected.  Not much damage. | Hard blow, but deflected |
| LEFT ARM | 3 |  | Quick slash to the [target]'s upper left arm!  Just a nick. |  |
| LEFT ARM | 7 |  | Slash to the [target]'s shield arm!  Shears off a thin layer of skin! | Shears off a thin layer of skin |
| LEFT ARM | 8 |  | Glancing slash to the [target]'s shield arm! | Glancing slash |
| LEFT ARM | 10 |  | Powerful slash just cracks the [target]'s shield arm! | Powerful slash just cracks |
| LEFT ARM | 15 |  | Deep slash to the [target]'s left forearm! |  |
| LEFT ARM | 20 |  | Off-balance slash to the [target]'s left arm shatters its elbow. "CRUNCH" | arm shatters its elbow |
| LEFT ARM | 25 |  | Hard slash to the [target]'s side!  Left arm no longer available for use. | arm no longer available for use |
| LEFT ARM | 35 |  | Spectacular slash!  The [target]'s left arm is neatly amputated! | arm is neatly amputated |
| LEFT ARM | 40 |  | Awesome slash severs the [target]'s left arm!  A jagged stump is all that remains! | A jagged stump is all that remains |
| RIGHT HAND | 0 |  | Near-miss!  That'll hurt tomorrow. | That'll hurt tomorrow |
| RIGHT HAND | 1 |  | Diagonal slash to the [target]'s weapon arm.  Strike misses but bruises a few knuckles. | Strike misses but bruises a few knuckles |
| RIGHT HAND | 3 |  | Wild slash bounces off the back of the [target]'s hand. | Wild slash bounces off the back |
| RIGHT HAND | 5 |  | Feint to the [target]'s head!  Quick flick at its weapon hand!  Nasty cut to right hand! | Quick flick at its weapon hand |
| RIGHT HAND | 7 |  | Strong slash to the [target]'s right hand cuts deep. | hand cuts deep |
| RIGHT HAND | 5 |  | Slash to the [target]'s weapon hand!  Several fingers fly! | Several fingers fly |
| RIGHT HAND | 10 |  | Rapped the [target]'s knuckles hard!  Right hand sounds broken. | hand sounds broken |
| RIGHT HAND | 15 |  | Jagged slash to the [target]'s right arm!  Cut clean through at the     wrist.  Need a hand? | Cut clean through at the     wrist |
| RIGHT HAND | 25 |  | Powerful slash trims the [target]'s fingernails...  and the remainder of its right hand! | and the remainder of its right hand |
| RIGHT HAND | 30 |  | Off-balanced slash!  Enough force to sever the [target]'s right hand!   Amazing! | Enough force to sever |
| LEFT HAND | 0 |  | Near-miss!  Knuckles kissed but little damage. | Knuckles kissed but little damage |
| LEFT HAND | 1 |  | Slash to the [target]'s shield arm.  Strike trims off a few fingernails. | Strike trims off a few fingernails |
| LEFT HAND | 3 |  | Wild slash scratches the back of the [target]'s hand. | Wild slash scratches the back |
| LEFT HAND | 5 |  | Slice to the [target]'s left fingers.  Nice move. |  |
| LEFT HAND | 7 |  | Deep cut to the [target]'s left hand!  Seems to have broken some fingers too. | Seems to have broken some fingers too |
| LEFT HAND | 8 |  | Slash to the [target]'s shield hand!  Several fingers fly! | Several fingers fly |
| LEFT HAND | 10 |  | Rapped the knuckles hard!  Left hand sounds broken. | Rapped the knuckles hard |
| LEFT HAND | 15 |  | Jagged slash to the [target]'s left arm!  Cut clean through at the      wrist. Need a hand? | Cut clean through at the      wrist |
| LEFT HAND | 25 |  | Powerful slash trims the [target]'s fingernails...  and the remainder of its left hand! | and the remainder of its left hand |
| LEFT HAND | 30 |  | Off-balanced slash!  Enough force to sever the [target]'s left hand!    Amazing! | Enough force to sever |
| RIGHT LEG | 0 |  | Quick feint to the [target]'s right foot!  Little extra damage. | Little extra damage |
| RIGHT LEG | 5 |  | Slash to the [target]'s right leg hits high!  Kinda makes your knees weak, huh? | Kinda makes your knees weak, huh |
| RIGHT LEG | 10 |  | Banged the [target]'s right shin.  That'll raise a good welt. | That'll raise a good welt |
| RIGHT LEG | 10 |  | Downward slash across the [target]'s right thigh!  Might not scar. | Downward slash across |
| RIGHT LEG | 17 |  | Deep, bloody slash to the [target]'s right thigh! | Deep, bloody slash |
| RIGHT LEG | 20 |  | Quick, powerful slash to the [target]'s right knee! | Quick, powerful slash to |
| RIGHT LEG | 25 |  | Strong slash to the [target]'s right leg!  Muscles exposed!  Not a pretty sight. | Not a pretty sight |
| RIGHT LEG | 30 |  | Wild downward slash severs the [target]'s right foot!  Bloody stump,     anyone? | Wild downward slash severs |
| RIGHT LEG | 40 |  | Powerful slash!  The [target]'s right leg is severed at the knee! | leg is severed at the knee |
| RIGHT LEG | 45 |  | Powerful slash leaves the [target] without a right leg! | Powerful slash leaves the |
| LEFT LEG | 0 |  | Light, bruising slash to the [target]'s left thigh. | Light, bruising slash to |
| LEFT LEG | 5 |  | Slash to the [target]'s left leg hits high!  Kinda makes your knees weak, huh? | Kinda makes your knees weak, huh |
| LEFT LEG | 10 |  | Banged the [target]'s left shin.  That'll raise a good welt. | That'll raise a good welt |
| LEFT LEG | 10 |  | Downward slash across the [target]'s left thigh!  Gouges bone! | Downward slash across |
| LEFT LEG | 17 |  | Deft slash to the [target]'s left leg digs deep!  Bone is chipped! | Bone is chipped |
| LEFT LEG | 20 |  | Quick, powerful slash to the [target]'s left knee! | Quick, powerful slash to |
| LEFT LEG | 25 |  | Weak diagonal slash catches the [target]'s left knee!  It is dislocated. | Weak diagonal slash catches |
| LEFT LEG | 30 |  | Wild downward slash severs the [target]'s left foot!  Bloody stump,      anyone? | Wild downward slash severs |
| LEFT LEG | 40 |  | Powerful slash!  The [target]'s left leg is severed at the knee! | leg is severed at the knee |
| LEFT LEG | 45 |  | Powerful slash leaves the [target] without a left leg! | Powerful slash leaves the |

## Steam  (131 messages, 17 fatal)

| sec | rank | F | message | current match |
|---|---|---|---|---|
| HEAD | 0 |  | Steam billows around the [target].  Invigorating. | Steam billows around |
| HEAD | 4 |  | Burst of steam to the head leaves the [target]'s face flushed. | Burst of steam to the head leaves |
| HEAD | 10 |  | Hot steam strike to face made the [target] flinch! | Hot steam strike to face made |
| HEAD | 16 |  | Hot vapors to face leave the [target] gasping. | Hot vapors to face leave |
| HEAD | 22 |  | Hot steam to the face causes the [target] to grimace in pain! | Hot steam to the face causes |
| HEAD | 28 |  | Spray of hot water vapors to face causes large blisters.  Painful, but at least it obscures the acne. | Painful, but at least it obscures the acne |
| HEAD | 34 |  | Exposure to overheated steam removes wrinkles along with face! | Exposure to overheated steam removes wrinkles along with face |
| HEAD | 40 | F | Scalding blast removes hair and peels back scalp to show bone! | Scalding blast removes hair and peels back scalp to show bone |
| HEAD | 46 | F | The [target]'s head is engulfed in a hot ball of steam.  Brain is nicely cooked! | head is engulfed in a hot ball of steam |
| HEAD | 52 | F | Superheated blast turns facial complexion to a curiously unhealthy pallor. | Superheated blast turns facial complexion to a curiously unhealthy pallor |
| NECK | 0 |  | Wisps of steam make the [target] hot under the collar. | hot under the collar |
| NECK | 3 |  | Hot steam raises the hair on the back of the [target]'s neck. | Hot steam raises the hair on the back |
| NECK | 5 |  | Steam catches the [target] in the neck causing minor discomfort. | in the neck causing minor discomfort |
| NECK | 10 |  | Hot burst to to neck leaves the [target] a li'l steamed! | a li'l steamed |
| NECK | 13 |  | Hot vapors cause noticeable discoloration in neck. | Hot vapors cause noticeable discoloration in neck |
| NECK | 16 |  | Scalding steam leaves the throat feeling sore but sterilized. | Scalding steam leaves the throat feeling sore but sterilized |
| NECK | 20 |  | Over exposure to hot steam leaves neck feeling stiff. | Over exposure to hot steam leaves neck feeling stiff |
| NECK | 27 | F | Seething steam strike to neck leaves it tender and juicy. | Seething steam strike to neck leaves it tender and juicy |
| NECK | 35 | F | The [target]'s neck is parboiled, leaves throat a li'l parched. | neck is parboiled, leaves throat a li'l parched |
| NECK | 41 | F | Blast of superheated steam cauterizes carotid artery, leading to instant death! | Blast of superheated steam cauterizes carotid artery, leading to instant death |
| RIGHT EYE | 0 |  | The [target] barely notices the puff of steam. | barely notices the puff of steam |
| RIGHT EYE | 1 |  | Hot vapors cause the [target]'s eyes to water profusely. | eyes to water profusely |
| RIGHT EYE | 4 |  | Steamy gust to the right eye causes the [target] to blink repeatedly. | to blink repeatedly |
| RIGHT EYE | 7 |  | The [target]'s right eye swells from hot gust of steam! | eye swells from hot gust of steam |
| RIGHT EYE | 15 |  | Right eye boiled in skull to a soft consistency! | eye boiled in skull to a soft consistency |
| RIGHT EYE | 22 |  | Extended exposure to hot steam fuses eyelid to cornea! | Extended exposure to hot steam fuses eyelid to cornea |
| RIGHT EYE | 30 |  | Hot steam blast causes cornea to blister!  Visual acuity noticeably diminished. | Hot steam blast causes cornea to blister |
| RIGHT EYE | 35 | F | Right eye bursts from pressure of boiling ocular fluid. | eye bursts from pressure of boiling ocular fluid |
| RIGHT EYE | 40 | F | Scalding jet eviscerates right eye! | Scalding jet eviscerates |
| RIGHT EYE | 45 | F | Steaming ocular fluid cooks eyeball evenly.  Hors d'oeuvres anyone? | Steaming ocular fluid cooks eyeball evenly |
| LEFT EYE | 0 |  | The [target] barely notices the puff of steam. | barely notices the puff of steam |
| LEFT EYE | 1 |  | Hot vapors cause the [target]'s eyes to water profusely. | eyes to water profusely |
| LEFT EYE | 4 |  | Steamy gust to the left eye causes the [target] to blink repeatedly. | to blink repeatedly |
| LEFT EYE | 7 |  | The [target]'s left eye swells from hot gust of steam! | eye swells from hot gust of steam |
| LEFT EYE | 15 |  | Left eye boiled in skull to a soft consistency! | eye boiled in skull to a soft consistency |
| LEFT EYE | 22 |  | Extended exposure to hot steam fuses eyelid to cornea! | Extended exposure to hot steam fuses eyelid to cornea |
| LEFT EYE | 30 |  | Hot steam blast causes cornea to blister!  Visual acuity noticeably diminished. | Hot steam blast causes cornea to blister |
| LEFT EYE | 35 | F | Left eye bursts from pressure of boiling ocular fluid. | eye bursts from pressure of boiling ocular fluid |
| LEFT EYE | 40 | F | Scalding jet eviscerates left eye! | Scalding jet eviscerates |
| LEFT EYE | 45 | F | Steaming ocular fluid cooks eyeball evenly.  Hors d'oeuvres anyone? | Steaming ocular fluid cooks eyeball evenly |
| CHEST | 0 |  | Steam billows around the [target].  Invigorating. | Steam billows around |
| CHEST | 4 |  | Hot gush of steam to the chest startles the [target]. | Hot gush of steam to the chest startles |
| CHEST | 8 |  | Sweltering vapors to upper body cause noticeable discomfort. | Sweltering vapors to upper body cause noticeable discomfort |
| CHEST | 15 |  | The [target] fails to avoid the steam fumes.  Strike leaves chest simmering. | fails to avoid the steam fumes |
| CHEST | 20 |  | Steamed ribs make fine soup bone! | Steamed ribs make fine soup bone |
| CHEST | 26 |  | Solid strike of steam peels back epidermis in large chunks! | Solid strike of steam peels back epidermis in large chunks |
| CHEST | 30 |  | Steaming strike turns lungs to pudding! | Steaming strike turns lungs to pudding |
| CHEST | 45 |  | Boiling steam strike to the [target]'s chest causes major heartburn.. and lungburn.. | chest causes major heartburn |
| CHEST | 55 | F | The [target]'s chest is cooked to tender perfection.  White meat or dark? | chest is cooked to tender perfection |
| CHEST | 65 | F | Superheated steam boils internal organs!  The [target]'s heart is boiled.. not broken. | Superheated steam boils internal organs |
| ABDOMEN | 0 |  | Warm mist covers the [target]'s abdomen.  Feels damp. | Warm mist covers |
| ABDOMEN | 4 |  | Hot steam makes the [target] feel warm all inside and out. | feel warm all inside and out |
| ABDOMEN | 8 |  | A hot gust of vapors to stomach reheats meal. | A hot gust of vapors to stomach reheats meal |
| ABDOMEN | 15 |  | The hot steam exposure causes skin to blister and redden. | The hot steam exposure causes skin to blister and redden |
| ABDOMEN | 20 |  | Seething vapors cause severe abdominal pains. | Seething vapors cause severe abdominal pains |
| ABDOMEN | 26 |  | Boiling vapors cooks abdomen evenly.  Haggis anyone? | Boiling vapors cooks abdomen evenly.  Haggis anyone |
| ABDOMEN | 30 |  | A steaming burst to the stomach sends the [target] reeling backwards. | A steaming burst to the stomach sends |
| ABDOMEN | 45 |  | Direct strike to abdomen leave the [target] simmering, stewed in its own juices! | simmering, stewed in its own juices |
| ABDOMEN | 55 | F | The [target]'s abdomen is parboiled.  The smell is nauseating. | The smell is nauseating |
| ABDOMEN | 65 | F | Superheated steam turns the [target]'s intestines into a fine delicacy! | intestines into a fine delicacy |
| BACK | 0 |  | Mist envelops the [target]'s back.  Made it sweat. | Mist envelops |
| BACK | 4 |  | Hot steam causes the [target] to squirm uncomfortably! | to squirm uncomfortably |
| BACK | 10 |  | Hot vapors to back cause the [target] to squirm in discomfort. | to squirm in discomfort |
| BACK | 15 |  | Close proximity to scalding mist cause minor burns to back side! | Close proximity to scalding mist cause minor burns to back side |
| BACK | 20 |  | Boiling steam reduces backside to blistering pulp! | Boiling steam reduces backside to blistering pulp |
| BACK | 26 |  | Strike to back leaves it simmering! | Strike to back leaves it simmering |
| BACK | 30 |  | Scaldling blast peels large layers of skin off the [target]'s back! | Scaldling blast peels large layers of skin off |
| BACK | 45 |  | Boiling strike to back leaves nerves raw and everything else steamed. | Boiling strike to back leaves nerves raw and everything else steamed |
| BACK | 55 |  | The [target]'s back is cooked to tender perfection. White meat or dark? | back is cooked to tender perfection |
| BACK | F |  | R3 Back/Nerves | R3 Back/Nerves |
| BACK | 65 | F | Superheated steam cooks the [target]'s spine and fuses nerves! | Superheated steam cooks |
| RIGHT ARM | 0 |  | Sprinkle of mist.  Not much else. | Sprinkle of mist |
| RIGHT ARM | 3 |  | The [target] flinches from the spurt of hot steam to its right arm. | flinches from the spurt of hot steam |
| RIGHT ARM | 7 |  | Excoriating vapors cause chafing of right arm. | Excoriating vapors cause chafing |
| RIGHT ARM | 8 |  | The [target] jerks right arm away from the hot steam. | arm away from the hot steam |
| RIGHT ARM | 10 |  | Scalding steam blisters right arm with painful splotches. | arm with painful splotches |
| RIGHT ARM | 17 |  | Boiling vapor strike leaves right arm quivering uncontrollably! | arm quivering uncontrollably |
| RIGHT ARM | 20 |  | The [target] cringes from a scalding blast to right arm! | cringes from a scalding blast |
| RIGHT ARM | 26 |  | Torrid steam blast to right arm cooks it to the bone! | arm cooks it to the bone |
| RIGHT ARM | 32 |  | Boiling stream strikes right arm!  Steamed, not fried. | Boiling stream strikes |
| RIGHT ARM | 45 |  | Overexposure to superheated steam reduces right arm to simmering tissue! | Overexposure to superheated steam reduces |
| LEFT ARM | 0 |  | Sprinkle of mist.  Not much else. | Sprinkle of mist |
| LEFT ARM | 3 |  | The [target] flinches from the spurt of hot steam to its left arm. | flinches from the spurt of hot steam |
| LEFT ARM | 7 |  | Excoriating vapors cause chafing of left arm. | Excoriating vapors cause chafing of left arm |
| LEFT ARM | 8 |  | The [target] jerks left arm away from the hot steam | arm away from the hot steam |
| LEFT ARM | 10 |  | Scalding steam blisters left arm with painful splotches. | arm with painful splotches |
| LEFT ARM | 17 |  | Boiling vapor strike leaves left arm quivering uncontrollably! | arm quivering uncontrollably |
| LEFT ARM | 20 |  | The [target] cringes from a scalding blast to left arm! | cringes from a scalding blast |
| LEFT ARM | 26 |  | Torrid steam blast to left arm cooks it to the bone! | arm cooks it to the bone |
| LEFT ARM | 32 |  | Boiling stream strikes left arm!  Steamed, not fried. | Boiling stream strikes |
| LEFT ARM | 45 |  | Overexposure to superheated steam reduces left arm to simmering tissue! | Overexposure to superheated steam reduces |
| RIGHT HAND | 0 |  | Moisturizing vapors cover the [target]'s right hand. | Moisturizing vapors cover |
| RIGHT HAND | 1 |  | The [target] jerks its right hand back as hot steam envelops it. | hand back as hot steam envelops it |
| RIGHT HAND | 3 |  | Brief exposure to hot vapors on right hand startles the [target]. | Brief exposure to hot vapors on right hand startles |
| RIGHT HAND | 5 |  | Blistering mist leaves The [target] holding its right hand tenderly! | Blistering mist leaves |
| RIGHT HAND | 7 |  | The [target] grimaces as hot droplets scald its right hand. | grimaces as hot droplets scald |
| RIGHT HAND | 8 |  | Boiling vapor strike to right hand causes loss of feeling in fingers! | Boiling vapor strike |
| RIGHT HAND | 10 |  | Boiling steam causes fingers to shrivel! | Boiling steam causes fingers to shrivel |
| RIGHT HAND | 15 |  | Overheated steam blast boils the [target]'s right hand! | Overheated steam blast boils |
| RIGHT HAND | 26 |  | Accurate steam gust severely burns the [target]'s right hand! | Accurate steam gust severely burns |
| RIGHT HAND | 28 |  | Blast of superheated steam shrivels the [target]'s right hand! | Blast of superheated steam shrivels |
| LEFT HAND | 0 |  | Moisturizing vapors cover the [target]'s left hand. | Moisturizing vapors cover |
| LEFT HAND | 1 |  | The [target] jerks its left hand back as hot steam envelops it. | hand back as hot steam envelops it |
| LEFT HAND | 3 |  | Brief exposure to hot vapors on left hand startles the [target]. | Brief exposure to hot vapors |
| LEFT HAND | 5 |  | Blistering mist leaves The [target] holding its left hand tenderly! | Blistering mist leaves |
| LEFT HAND | 7 |  | The [target] grimaces as hot droplets scald its left hand. | grimaces as hot droplets scald |
| LEFT HAND | 8 |  | Boiling vapor strike to left hand causes loss of feeling in fingers! | Boiling vapor strike |
| LEFT HAND | 10 |  | Boiling steam causes fingers to shrivel! | Boiling steam causes fingers to shrivel |
| LEFT HAND | 15 |  | Overheated steam blast boils the [target]'s left hand! | Overheated steam blast boils |
| LEFT HAND | 26 |  | Accurate steam gust severely burns the [target]'s left hand! | Accurate steam gust severely burns |
| LEFT HAND | 28 |  | Blast of superheated steam shrivels the [target]'s left hand! | Blast of superheated steam shrivels |
| RIGHT LEG | 0 |  | A tepid mist clings to the [target]'s right leg.  Feels clammy. | A tepid mist clings |
| RIGHT LEG | 5 |  | Hot steam spray to the leg makes the [target] jump back. | Hot steam spray to the leg makes |
| RIGHT LEG | 10 |  | Hot vapors cause reddening of skin on right leg. | Hot vapors cause reddening of skin on right leg |
| RIGHT LEG | 15 |  | The [target] shakes its right leg trying to cool off hot clinging mist. | leg trying to cool off hot clinging mist |
| RIGHT LEG | 17 |  | Scouring steam strips skin from right leg! | Scouring steam strips skin |
| RIGHT LEG | 20 |  | The [target] staggers from hot steam blast to right leg! | staggers from hot steam blast |
| RIGHT LEG | 24 |  | Fuming water vapors make the [target]'s knees all wobbly. | Fuming water vapors make |
| RIGHT LEG | 30 |  | Exposure to broiling vapors render right leg barely usable! | Exposure to broiling vapors render |
| RIGHT LEG | 38 |  | An accurate strike renders the [target]'s right leg to a steaming lump of flesh! | An accurate strike renders |
| RIGHT LEG | 43 |  | Exposure to superheated steam renders right leg useless but fat-free! | Exposure to superheated steam renders |
| LEFT LEG | 0 |  | A tepid mist clings to the [target]'s left leg.  Feels clammy. | A tepid mist clings |
| LEFT LEG | 5 |  | Hot steam spray to the leg makes the [target] jump back. | Hot steam spray to the leg makes |
| LEFT LEG | 10 |  | Hot vapors cause reddening of skin on left leg. | Hot vapors cause reddening of skin |
| LEFT LEG | 15 |  | The [target] shakes its left leg trying to cool off hot clinging mist. | leg trying to cool off hot clinging mist |
| LEFT LEG | 17 |  | Scouring steam strips skin from left leg! | Scouring steam strips skin |
| LEFT LEG | 20 |  | The [target] staggers from hot steam blast to left leg! | staggers from hot steam blast |
| LEFT LEG | 24 |  | Fuming water vapors make the [target]'s knees all wobbly. | Fuming water vapors make |
| LEFT LEG | 30 |  | Exposure to broiling vapors render left leg barely usable! | Exposure to broiling vapors render |
| LEFT LEG | 38 |  | An accurate strike renders the [target]'s left leg to a steaming lump of flesh! | An accurate strike renders |
| LEFT LEG | 43 |  | Exposure to superheated steam renders left leg useless but fat-free! | Exposure to superheated steam renders |

## Unbalance  (130 messages, 4 fatal)

| sec | rank | F | message | current match |
|---|---|---|---|---|
|  | 0 |  | Slight push to the [target]'s face. |  |
|  | 1 |  | Strike to head dizzies the [target]. | Strike to head dizzies |
|  | 2 |  | Strike to forehead causes the [target] momentary dizziness. | momentary dizziness |
|  | 3 |  | Just like a brick to the head, without the imprint. | Just like a brick to the head, without the imprint |
|  | 4 |  | Blow to the side of the [target]'s head! | Blow to the side |
|  | 5 |  | Head strike stuns the [target]. | Head strike stuns the |
|  | 6 |  | Control of body lost.  The [target] falls to the ground stunned. | falls to the ground stunned |
|  | 7 |  | Control of body lost.  The [target] falls to the ground stunned. | falls to the ground stunned |
|  | 8 |  | Blow to the head shorts brain. The [target] falls as body control is lost. | Blow to the head shorts brain |
|  | 9 | F | Awesome strike to the head! The [target] is knocked to the ground dead. | is knocked to the ground dead |
|  | 0 |  | Slight push to the [target]'s neck. |  |
|  | 1 |  | Throat strike causes the [target] to cough. | Throat strike causes |
|  | 2 |  | Strike to voicebox. The [target] is speechless! | Strike to voicebox |
|  | 3 |  | Whiplash! |  |
|  | 4 |  | Air supply cut off by sharp strike, the [target]'s eyes bulge! | Air supply cut off by sharp strike |
|  | 5 |  | Neck shot. The [target] is knocked onto her back. | is knocked onto her back |
|  | 6 |  | Strike to neck throws opponent to the ground violently. | Strike to neck throws opponent to the ground violently |
|  | 7 |  | Strike to neck throws opponent to the ground violently. | Strike to neck throws opponent to the ground violently |
|  | 8 |  | Blow to neck throws  to the ground violently. | Blow to neck throws  to the ground violently |
|  | 9 | F | Neck strike throws the [target], snapping its neck in the process. | snapping its neck in the process |
|  | 0 |  | Weak strike makes the [target]'s eye bloodshot. | Weak strike makes |
|  | 1 |  | The [target]'s right eye swells suddenly, causing great pain. | eye swells suddenly, causing great pain |
|  | 2 |  | Eye swells shut momentarily. | Eye swells shut momentarily |
|  | 3 |  | Nice shiner to right eye! |  |
|  | 4 |  | Dizzied! The [target] spins in circles. | spins in circles |
|  | 5 |  | Vision blurred. The [target] staggers around blindly. | staggers around blindly |
|  | 6 |  | Blow to the eye dazes the [target]. The [target] struggles to recover. | Blow to the eye dazes |
|  | 7 |  | Optic nerves scrambled. The [target] struggles on the ground to recover. | struggles on the ground to recover |
|  | 8 |  | Optic nerves scrambled. The [target] struggles to recover balance but fails. | struggles to recover balance but fails |
|  | 9 | F | Eye spins backward into skull. The [target] falls to the ground dead. | falls to the ground dead |
|  | 0 |  | Weak strike makes the [target]'s eye bloodshot. | Weak strike makes |
|  | 1 |  | The [target]'s left eye swells suddenly, causing great pain. | eye swells suddenly, causing great pain |
|  | 2 |  | Eye swells shut momentarily. | Eye swells shut momentarily |
|  | 3 |  | Nice shiner to left eye! |  |
|  | 4 |  | Dizzied! The [target] spins in circles. | spins in circles |
|  | 5 |  | Vision blurred. The [target] staggers around blindly. | staggers around blindly |
|  | 6 |  | Blow to the eye dazes the [target]. The [target] struggles to recover. | Blow to the eye dazes |
|  | 7 |  | Optic nerves scrambled. The [target] struggles on the ground to recover. | struggles on the ground to recover |
|  | 8 |  | Optic nerves scrambled. The [target] struggles to recover balance but fails. | struggles to recover balance but fails |
|  | 9 | F | Eye spins backward into skull. The [target] falls to the ground dead. | falls to the ground dead |
|  | 0 |  | Minor bruise to chest. | Minor bruise to chest |
|  | 1 |  | Chest hit causes the [target] to spin around like a halfling / after a fresh tart. | to spin around like a halfling / after a fresh tart |
|  | 2 |  | Side strike shoves the [target] several feet sideways. | several feet sideways |
|  | 3 |  | Oof!  Sudden impact knocks the wind out of the [target]. | Sudden impact knocks the wind out |
|  | 4 |  | The [target] hits self trying to recover balance. | hits self trying to recover balance |
|  | 5 |  | Chest strike sprawls opponent flat on back. | Chest strike sprawls opponent flat on back |
|  | 6 |  | Chest strike.  Opponent knocked back and stunned! | Chest strike.  Opponent knocked back and stunned |
|  | 7 |  | Chest strike.  Opponent knocked down stunned! | Chest strike.  Opponent knocked down |
|  | 8 |  | Chest strike.  Opponent knocked down stunned! | Chest strike.  Opponent knocked down |
|  | 9 |  | The [target] drops to the ground like a sack of potatoes. | drops to the ground like a sack of potatoes |
|  | 0 |  | Feeble stomach strike. | Feeble stomach strike |
|  | 1 |  | Stomach strike knocks the [target] backwards several feet. | backwards several feet |
|  | 2 |  | Invisible force gives the [target] a rabbit punch. | Invisible force gives the |
|  | 3 |  | Upward thrust lifts the [target] several inches off the ground. | several inches off the ground |
|  | 4 |  | Vertigo! The [target] clutches stomach. | clutches stomach |
|  | 5 |  | Waves of nausea spread from stomach, incapacitating the [target]. | Waves of nausea spread from stomach, incapacitating |
|  | 6 |  | Strike to solar plexus stuns the [target]. | Strike to solar plexus stuns |
|  | 7 |  | Strike to solar plexus stuns the [target]. | Strike to solar plexus stuns |
|  | 8 |  | Strike to solar plexus drops the [target] to the ground, stunned. | Strike to solar plexus drops |
|  | 9 |  | Strike to stomach sends the [target] doubling over to the ground. | doubling over to the ground |
|  | 0 |  | Tickled the [target]'s back muscles. Minor lumbago. | Minor lumbago |
|  | 1 |  | Strike to back throws the [target] off balance momentarily. | off balance momentarily |
|  | 2 |  | Severe low back pain! The [target] gasps. | Severe low back pain |
|  | 3 |  | The [target] stumbles forward, off balance. | stumbles forward, off balance |
|  | 4 |  | Footing lost! The [target] wrenches back trying to stay upright. | wrenches back trying to stay upright |
|  | 5 |  | Back strike. Opponent writhes in pain. | Opponent writhes in pain |
|  | 6 |  | Strike to lower back stuns the [target]. | Strike to lower back stuns |
|  | 7 |  | Strike to lower back stuns the [target]. | Strike to lower back stuns |
|  | 8 |  | Strike to lower back drops the [target] to the ground, stunned. | Strike to lower back drops |
|  | 9 |  | The [target] is thrown to the ground face first! / A very hard landing! | is thrown to the ground face first |
|  | 0 |  | Slight twitching in the [target]'s weapon arm. | Slight twitching |
|  | 1 |  | The [target]'s weapon arm twists oddly but snaps right back. | weapon arm twists oddly but snaps |
|  | 2 |  | Jarring blow to the [target]'s weapon arm. | Jarring blow |
|  | 3 |  | Elbow wrenched. | Elbow wrenched |
|  | 4 |  | Arm jerked painfully upward. | Arm jerked painfully upward |
|  | 5 |  | Opponent's arm snaps trying to prevent fall. | Opponent's arm snaps trying to prevent fall |
|  | 6 |  | Strike to arm spins opponent like a top. The [target] is stunned. | Strike to arm spins opponent like a top |
|  | 7 |  | Strike to arm spins opponent like a top. The [target] is stunned. | Strike to arm spins opponent like a top |
|  | 8 |  | Strike to arm spins opponent like a top. The [target] is stunned. | Strike to arm spins opponent like a top |
|  | 9 |  | Spun clockwise, the [target] falls in a heap. | falls in a heap |
|  | 0 |  | Slight twitching in the [target]'s shield arm. | Slight twitching |
|  | 1 |  | The [target]'s shield arm twists oddly but snaps right back. | shield arm twists oddly but snaps |
|  | 2 |  | Jarring blow to the [target]'s shield arm. | Jarring blow |
|  | 3 |  | Elbow wrenched. | Elbow wrenched |
|  | 4 |  | Arm jerked painfully upward. | Arm jerked painfully upward |
|  | 5 |  | Opponent's arm snaps trying to prevent fall. | Opponent's arm snaps trying to prevent fall |
|  | 6 |  | Strike to arm spins opponent like a top. The [target] is stunned. | Strike to arm spins opponent like a top |
|  | 7 |  | Strike to arm spins opponent like a top. The [target] is stunned. | Strike to arm spins opponent like a top |
|  | 8 |  | Shattered the arm below the elbow, leaving only bloody strips of flesh. | Shattered the arm below the elbow, leaving only bloody strips of flesh |
|  | 9 |  | Spun counterclockwise, the [target] falls in a heap. | Spun counterclockwise |
|  | 0 |  | Broken fingernail! How disastrous. | Broken fingernail |
|  | 1 |  | The [target]'s wrist twisted slightly. | wrist twisted slightly |
|  | 2 |  | Finger jams and swells. | Finger jams and swells |
|  | 3 |  | Shot to hand spins the [target] in circles. | Shot to hand spins |
|  | 4 |  | Right hand slammed. Finger broken! | Finger broken |
|  | 5 |  | The [target]'s hand injured grasping for support. | hand injured grasping for support |
|  | 6 |  | The [target] stunned by strike to hand. | stunned by strike to hand |
|  | 7 |  | The [target] stunned by strike to hand. | stunned by strike to hand |
|  | 8 |  | The [target] stunned by strike to hand. | stunned by strike to hand |
|  | 9 |  | Hand struck hard! Pain causes the [target] to wobble dizzily before falling. | to wobble dizzily before falling |
|  | 0 |  | Broken fingernail! How disastrous. | Broken fingernail |
|  | 1 |  | The [target]'s wrist twisted slightly. | wrist twisted slightly |
|  | 2 |  | Finger jams and swells. | Finger jams and swells |
|  | 3 |  | Shot to hand spins the [target] in circles. | Shot to hand spins |
|  | 4 |  | Left hand slammed. Finger broken! | Finger broken |
|  | 5 |  | The [target]'s hand injured grasping for support. | hand injured grasping for support |
|  | 6 |  | The [target] stunned by strike to hand. | stunned by strike to hand |
|  | 7 |  | The [target] stunned by strike to hand. | stunned by strike to hand |
|  | 8 |  | The [target] stunned by strike to hand. | stunned by strike to hand |
|  | 9 |  | Hand struck hard! Pain causes the [target] to wobble dizzily before falling. | to wobble dizzily before falling |
|  | 0 |  | Charlie horse to the right leg!  That should stop the [target]. | That should stop |
|  | 1 |  | The [target]'s right leg jerks momentarily. | leg jerks momentarily |
|  | 2 |  | Pop! Kneecap wrenched. | Kneecap wrenched |
|  | 3 |  | Sprained ankle! The [target] won't be running soon. | won't be running soon |
|  | 4 |  | Strike to foot! The [target] hops around dizzily on the other foot and falls. | hops around dizzily on the other foot and falls |
|  | 5 |  | Leg strike sends waves of pain through the [target]. | Leg strike sends waves of pain |
|  | 6 |  | Leg jerked violently. The [target] is stunned. | Leg jerked violently |
|  | 7 |  | The [target]'s kneecap shatters sending bone fragments flying. | kneecap shatters sending bone fragments flying |
|  | 8 |  | You shatter the [target]'s right leg from the knee down. | leg from the knee down |
|  | 9 |  | The [target] tries desperately to keep footing, but falls on rear instead. | tries desperately to keep footing, but falls on rear instead |
|  | 0 |  | Charlie horse to the left leg!  That should stop the [target] | That should stop |
|  | 1 |  | The [target]'s left leg jerks momentarily. | leg jerks momentarily |
|  | 2 |  | Pop! Kneecap wrenched. | Kneecap wrenched |
|  | 3 |  | Sprained ankle! The [target] won't be running soon. | won't be running soon |
|  | 4 |  | Strike to foot! The [target] hops around dizzily on the other foot and falls. | hops around dizzily on the other foot and falls |
|  | 5 |  | Leg strike sends waves of pain through the [target]. | Leg strike sends waves of pain |
|  | 6 |  | Leg jerked violently. The [target] is stunned. | Leg jerked violently |
|  | 7 |  | The [target]'s kneecap shatters sending bone fragments flying. | kneecap shatters sending bone fragments flying |
|  | 8 |  | You shatter the [target]'s left leg from the knee down. | leg from the knee down |
|  | 9 |  | The [target] tries desperately to keep footing, but falls on rear instead. | tries desperately to keep footing, but falls on rear instead |

## Vacuum  (130 messages, 20 fatal)

| sec | rank | F | message | current match |
|---|---|---|---|---|
| HEAD | 0 |  | Ears pop, neat effect. | Ears pop, neat effect |
| HEAD | 5 |  | Ears pop loudly! | Ears pop loudly |
| HEAD | 10 |  | Blood trickles from nose! | Blood trickles from nose |
| HEAD | 15 |  | Eyes bulge and blood trickles from ears and nose! | Eyes bulge and blood trickles from ears and nose |
| HEAD | 20 |  | Blood gushes from ears and nose! | Blood gushes from ears and nose |
| HEAD | 25 |  | Decompression causes skull to crack, blood comes from ears and nose in a spurt! | Decompression causes skull to crack, blood comes from ears and nose in a spurt |
| HEAD | 30 | F | Massive decompression causes head to erupt in an explosion of brain and bone! Messy! | Massive decompression causes head to erupt in an explosion of brain and bone |
| HEAD | 35 | F | Decompression liquifies what little brain the [target] had! | Decompression liquifies what little brain |
| HEAD | 40 | F | Head decompresses and blood erupts from all orifices! | Head decompresses and blood erupts from all orifices |
| HEAD | 50 | F | Head is vaporized by decompression! | Head is vaporized by decompression |
| NECK | 0 |  | Swallows hard, sore but nothing else. | Swallows hard, sore but nothing else |
| NECK | 2 |  | Veins in neck stand out briefly! | Veins in neck stand out briefly |
| NECK | 5 |  | Throat swells to near bursting! | Throat swells to near bursting |
| NECK | 10 |  | Veins in neck swell | Veins in neck swell |
| NECK | 12 |  | Veins in neck burst and throat swells! | Veins in neck burst and throat swells |
| NECK | 15 |  | Neck erupts in a gory spurt of blood! | Neck erupts in a gory spurt of blood |
| NECK | 20 | F | In a massive display of gore, the [target]'s neck explodes violently! | In a massive display of gore |
| NECK | 25 | F | Neck explodes outward and severs spine, gruesome! | Neck explodes outward and severs spine, gruesome |
| NECK | 30 | F | Jugular veins erupt in twin fountains!  Too bad the [target] needed them to live. | Jugular veins erupt in twin fountains |
| NECK | 40 | F | Neck is vaporized by decompression! | Neck is vaporized by decompression |
| RIGHT EYE | 0 |  | Eye gets a little bloodshot. | Eye gets a little bloodshot |
| RIGHT EYE | 1 |  | Eye swells under sudden pressure loss! | Eye swells under sudden pressure loss |
| RIGHT EYE | 3 |  | Blood vessels in eyes burst! | Blood vessels in eyes burst |
| RIGHT EYE | 5 |  | Eye swells and bulges as blood vessels burst! | Eye swells and bulges as blood vessels burst |
| RIGHT EYE | 10 |  | Eye bursts, the [target] howls in pain! | howls in pain |
| RIGHT EYE | 20 |  | Decompression ruptures eye!  Ocular fluid spurts! | Decompression ruptures eye!  Ocular fluid spurts |
| RIGHT EYE | 30 |  | Eyes burst followed by a stream of blood and brain, what a mess! | Eyes burst followed by a stream of blood and brain, what a mess |
| RIGHT EYE | 40 | F | Eye erupts, followed by a spurt of blood from the nose! Brain no longer intact. | Eye erupts, followed by a spurt of blood from the nose |
| RIGHT EYE | 45 | F | Decompression causes eyes to explode, unfortunately it takes most of the [target]'s face with it too! | Decompression causes eyes to explode, unfortunately it takes most |
| RIGHT EYE | 50 | F | Eye bursts and decompression takes most of the [target]'s head with it! | Eye bursts and decompression takes most |
| LEFT EYE | 0 |  | Eye gets a little bloodshot. | Eye gets a little bloodshot |
| LEFT EYE | 1 |  | Eye swells under sudden pressure loss! | Eye swells under sudden pressure loss |
| LEFT EYE | 3 |  | Blood vessels in eyes burst! | Blood vessels in eyes burst |
| LEFT EYE | 5 |  | Eye swells and bulges as blood vessels burst! | Eye swells and bulges as blood vessels burst |
| LEFT EYE | 10 |  | Eye bursts, the [target] howls in pain! | howls in pain |
| LEFT EYE | 20 |  | Decompression ruptures eye!  Ocular fluid spurts! | Decompression ruptures eye!  Ocular fluid spurts |
| LEFT EYE | 30 |  | Eyes burst followed by a stream of blood and brain, what a mess! | Eyes burst followed by a stream of blood and brain, what a mess |
| LEFT EYE | 40 | F | Eye erupts, followed by a spurt of blood from the nose! Brain no longer intact. | Eye erupts, followed by a spurt of blood from the nose |
| LEFT EYE | 45 | F | Decompression causes eyes to explode, unfortunately it takes most of the [target]'s face with it too! | Decompression causes eyes to explode, unfortunately it takes most |
| LEFT EYE | 50 | F | Eye bursts and decompression takes most of the [target]'s head with it! | Eye bursts and decompression takes most |
| CHEST | 0 |  | Attention getter. | Attention getter |
| CHEST | 5 |  | Chest heaves as air rushes away from it! | Chest heaves as air rushes away from it |
| CHEST | 10 |  | Ribs crack as chest swells! | Ribs crack as chest swells |
| CHEST | 15 |  | Chest swells, breaking ribs! | Chest swells, breaking ribs |
| CHEST | 20 |  | Sternum snaps followed by many ribs! | Sternum snaps followed by many ribs |
| CHEST | 25 |  | Ribs shatter and blood fills lungs! | Ribs shatter and blood fills lungs |
| CHEST | 30 |  | Chest expands and ribs snap, piercing lungs! | Chest expands and ribs snap, piercing lungs |
| CHEST | 50 |  | Ribs shatter outward spraying bone everywhere, exposing a still beating heart! | Ribs shatter outward spraying bone everywhere, exposing a still beating heart |
| CHEST | 60 | F | Chest heaves, lungs rupture ruining an otherwise good day! | Chest heaves, lungs rupture ruining an otherwise good day |
| CHEST | 70 | F | Chest decompresses violently and explodes in a shower of bone and lung! | Chest decompresses violently and explodes in a shower of bone and lung |
| ABDOMEN | 0 |  | Attention getter. | Attention getter |
| ABDOMEN | 5 |  | Abdomen swells as the air rushes away from it! | Abdomen swells as the air rushes away from it |
| ABDOMEN | 10 |  | Stomach distends and the [target] coughs up blood! | Stomach distends |
| ABDOMEN | 15 |  | Abdomen swells, internal organs rupture! | Abdomen swells, internal organs rupture |
| ABDOMEN | 20 |  | Abdomen bulges greatly and organs rupture! | Abdomen bulges greatly and organs rupture |
| ABDOMEN | 25 |  | Internal organs strain and burst under decompression! | Internal organs strain and burst under decompression |
| ABDOMEN | 30 |  | Vital organs swell and tear, the [target] howls in pain! | Vital organs swell and tear |
| ABDOMEN | 50 |  | Internal organs rearranged!  VERY uncomfortable. | Internal organs rearranged |
| ABDOMEN | 60 | F | Internal organs erupt outward spraying violently and dies horribly! | Internal organs erupt outward spraying violently and dies horribly |
| ABDOMEN | 70 | F | Abdomen erupts, blood and bile splatter everything! | Abdomen erupts, blood and bile splatter everything |
| BACK | 0 |  | Attention getter. | Attention getter |
| BACK | 5 |  | Back pops as muscles resist the vacuum! | Back pops as muscles resist the vacuum |
| BACK | 10 |  | Back swells and bones crack! | Back swells and bones crack |
| BACK | 15 |  | Back strains under sudden decompression! | Back strains under sudden decompression |
| BACK | 20 |  | Spine cracks! | Spine cracks |
| BACK | 25 |  | Back snaps as ribs and vertebrae separate! | Back snaps as ribs and vertebrae separate |
| BACK | 30 |  | Back bones shatter in sudden pressure drop! | Back bones shatter in sudden pressure drop |
| BACK | 50 |  | Spine and shoulders snap as they expand outward! | Spine and shoulders snap as they expand outward |
| BACK | 60 | F | Spine leaps out and shatters into many small pieces! | Spine leaps out and shatters into many small pieces |
| BACK | 70 | F | Back erupts in a bloody display of bone and gore! | Back erupts in a bloody display of bone and gore |
| RIGHT ARM | 0 |  | Slight tug on the arm. | Slight tug on the arm |
| RIGHT ARM | 3 |  | Veins in arm stand out briefly! | Veins in arm stand out briefly |
| RIGHT ARM | 7 |  | Blood vessels in arm burst! | Blood vessels in arm burst |
| RIGHT ARM | 8 |  | Decompression causes muscles in arm to crack! | Decompression causes muscles in arm to crack |
| RIGHT ARM | 10 |  | Elbow shatters under sudden decompression! | Elbow shatters under sudden decompression |
| RIGHT ARM | 15 |  | Bones in arm crack and blood vessels burst! | Bones in arm crack and blood vessels burst |
| RIGHT ARM | 20 |  | Upper and lower arm shatter as they decompress! | Upper and lower arm shatter as they decompress |
| RIGHT ARM | 25 |  | Bones in right arm shatter violently leaving behind a bloody stump! | arm shatter violently leaving behind a bloody stump |
| RIGHT ARM | 35 |  | Right arm explodes at the shoulder! | arm explodes at the shoulder |
| RIGHT ARM | 40 |  | Right arm explodes into thousands of pieces! | arm explodes into thousands of pieces |
| LEFT ARM | 0 |  | Slight tug on the arm. | Slight tug on the arm |
| LEFT ARM | 3 |  | Veins in arm stand out briefly! | Veins in arm stand out briefly |
| LEFT ARM | 7 |  | Blood vessels in arm burst! | Blood vessels in arm burst |
| LEFT ARM | 8 |  | Decompression causes muscles in arm to crack! | Decompression causes muscles in arm to crack |
| LEFT ARM | 10 |  | Elbow shatters under sudden decompression! | Elbow shatters under sudden decompression |
| LEFT ARM | 20 |  | Bones in arm crack and blood vessels burst! | Bones in arm crack and blood vessels burst |
| LEFT ARM | 20 |  | Upper and lower arm shatter as they decompress! | Upper and lower arm shatter as they decompress |
| LEFT ARM | 25 |  | Bones in left arm shatter violently leaving behind a bloody stump! | arm shatter violently leaving behind a bloody stump |
| LEFT ARM | 35 |  | Left arm explodes at the shoulder! | arm explodes at the shoulder |
| LEFT ARM | 40 |  | Left arm explodes into thousands of pieces! | arm explodes into thousands of pieces |
| RIGHT HAND | 0 |  | Fingernail cracks! | Fingernail cracks |
| RIGHT HAND | 1 |  | Fingernail explodes! | Fingernail explodes |
| RIGHT HAND | 3 |  | Knuckles pop and bleed! | Knuckles pop and bleed |
| RIGHT HAND | 5 |  | Veins in hand burst! | Veins in hand burst |
| RIGHT HAND | 7 |  | Fingernails burst and blood sprays out! | Fingernails burst and blood sprays out |
| RIGHT HAND | 8 |  | Knuckles in hand erupt, blood flows freely! | Knuckles in hand erupt, blood flows freely |
| RIGHT HAND | 10 |  | Fingers and hand erupt bloodily! | Fingers and hand erupt bloodily |
| RIGHT HAND | 15 |  | Bones in right hand shatter violently leaving behind a bloody stump! | hand shatter violently leaving behind a bloody stump |
| RIGHT HAND | 25 |  | Right hand explodes at the wrist! | hand explodes at the wrist |
| RIGHT HAND | 40 |  | Right hand explodes into thousands of pieces! | hand explodes into thousands of pieces |
| LEFT HAND | 0 |  | Fingernail cracks! | Fingernail cracks |
| LEFT HAND | 1 |  | Fingernail explodes! | Fingernail explodes |
| LEFT HAND | 3 |  | Knuckles pop and bleed! | Knuckles pop and bleed |
| LEFT HAND | 5 |  | Veins in hand burst! | Veins in hand burst |
| LEFT HAND | 7 |  | Fingernails burst and blood sprays out! | Fingernails burst and blood sprays out |
| LEFT HAND | 8 |  | Knuckles in hand erupt, blood flows freely! | Knuckles in hand erupt, blood flows freely |
| LEFT HAND | 10 |  | Fingers and hand erupt bloodily! | Fingers and hand erupt bloodily |
| LEFT HAND | 15 |  | Bones in left hand shatter violently leaving behind a bloody stump! | hand shatter violently leaving behind a bloody stump |
| LEFT HAND | 25 |  | Left hand explodes at the wrist! | hand explodes at the wrist |
| LEFT HAND | 40 |  | Left hand explodes into thousands of pieces! | hand explodes into thousands of pieces |
| RIGHT LEG | 0 |  | Slight tug on the leg | Slight tug on the leg |
| RIGHT LEG | 3 |  | Legs wobble slightly! | Legs wobble slightly |
| RIGHT LEG | 10 |  | Blood vessels in leg burst! | Blood vessels in leg burst |
| RIGHT LEG | 15 |  | Decompression causes muscles in leg to snap! | Decompression causes muscles in leg to snap |
| RIGHT LEG | 17 |  | Knee shatters under sudden decompression! | Knee shatters under sudden decompression |
| RIGHT LEG | 20 |  | Bones in leg crack and blood vessels burst! | Bones in leg crack and blood vessels burst |
| RIGHT LEG | 25 |  | Upper and lower leg shatter as they decompress! | Upper and lower leg shatter as they decompress |
| RIGHT LEG | 30 |  | Bones in right leg shatter violently leaving behind a bloody stump! | leg shatter violently leaving behind a bloody stump |
| RIGHT LEG | 40 |  | Right leg explodes at the hip! | leg explodes at the hip |
| RIGHT LEG | 45 |  | Right leg explodes into thousands of pieces! | leg explodes into thousands of pieces |
| LEFT LEG | 0 |  | Slight tug on the leg | Slight tug on the leg |
| LEFT LEG | 3 |  | Legs wobble slightly! | Legs wobble slightly |
| LEFT LEG | 10 |  | Blood vessels in leg burst! | Blood vessels in leg burst |
| LEFT LEG | 15 |  | Decompression causes muscles in leg to snap! | Decompression causes muscles in leg to snap |
| LEFT LEG | 17 |  | Knee shatters under sudden decompression! | Knee shatters under sudden decompression |
| LEFT LEG | 20 |  | Bones in leg crack and blood vessels burst! | Bones in leg crack and blood vessels burst |
| LEFT LEG | 25 |  | Upper and lower leg shatter as they decompress! | Upper and lower leg shatter as they decompress |
| LEFT LEG | 30 |  | Bones in left leg shatter violently leaving behind a bloody stump! | leg shatter violently leaving behind a bloody stump |
| LEFT LEG | 40 |  | Left leg explodes at the hip! | leg explodes at the hip |
| LEFT LEG | 45 |  | Left leg explodes into thousands of pieces! | leg explodes into thousands of pieces |


---

# Crit highlight fix-list (numbered)
Change each rule's match text to the `suggest:` value (or your own pick from `full:`).
A few have no good substring (whole message is generic) — flagged "no safe substring".


### Acid
1. [Acid damage] "Barely touched"  — no safe substring (full message is generic): Barely touched. Too bad the [target] ducked!

### Cold
2. [Cold damage] "Chilly blast"  ->  suggest: "Chilly blast to the head"
      full: Chilly blast to the head.  Bet the [target]'s ears are tingling!

### Crush
3. [Crush damage] "A feeble blow"  ->  suggest: "A feeble blow to the"
      full: A feeble blow to the [target]'s right arm!
4. [Crush damage] "Flattened the"  — no safe substring (full message is generic): Flattened the [target]'s right hand.
5. [Crush damage] "Glancing blow"  ->  suggest: "Glancing blow to the"
      full: Glancing blow to the [target]'s right leg!
6. [Crush damage] "Hit glances off"  ->  suggest: "Hit glances off the"
      full: Hit glances off the [target]'s hip.
7. [Crush damage] "Jarring blow"  ->  suggest: "Jarring blow to the"
      full: Jarring blow to the [target]'s back.
8. [Crush damage] "Love tap upside"  ->  suggest: "Love tap upside the"
      full: Love tap upside the [target]'s head!

### Disintegration
9. [Disintegration damage] "Grazing strike"  ->  suggest: "All the fingernails are melted as the"
      full: All the fingernails are melted as the right hand takes a grazing strike.
10. [Disintegration damage] "head to tilt"  ->  suggest: "Side of neck disintegrated, causing the"
      full: Side of neck disintegrated, causing the [target]'s head to tilt left.
11. [Disintegration damage] "Unpleasant wound"  ->  suggest: "Unpleasant wound to"
      full: Unpleasant wound to right arm!

### Disruption
12. [Disruption damage] "a mild headache"  ->  suggest: "Veins bulge on forehead, giving the"
      full: Veins bulge on forehead, giving the [target] a mild headache.
13. [Disruption damage] "Bones shatter"  ->  suggest: "Bones shatter in the"
      full: Bones shatter in the [target]'s weapon arm.
14. [Disruption damage] "Flesh bubbles"  ->  suggest: "Flesh bubbles on the"
      full: Flesh bubbles on the [target]'s right leg.
15. [Disruption damage] "Flesh flayed"  ->  suggest: "Strips of flesh flayed from the"
      full: Strips of flesh flayed from the [target]'s back.

### Electric
16. [Electric damage] "arm numbs elbow"  ->  suggest: "Heavy shock to"
      full: Heavy shock to right arm numbs elbow.
17. [Electric damage] "Definitely uncomfortable"  ->  suggest: "Nasty jolt to back fuses a few vertebrae"
      full: Nasty jolt to back fuses a few vertebrae. Definitely uncomfortable.
18. [Electric damage] "Fingers go numb"  ->  suggest: "Heavy shock to"
      full: Heavy shock to right hand. Fingers go numb.
19. [Electric damage] "Fingers tingle"  ->  suggest: "Light shock to"
      full: Light shock to right hand. Fingers tingle.
20. [Electric damage] "Shocking jolt"  ->  suggest: "Shocking jolt to forehead"
      full: Shocking jolt to forehead. Painful.
21. [Electric damage] "Static discharge"  ->  suggest: "Static discharge to back"
      full: Static discharge to back. Doesn't hurt, much.
22. [Electric damage] "stomach turn"  ->  suggest: "Nasty jolt to abdomen makes a"
      full: Nasty jolt to abdomen makes a [target]'s stomach turn. Urp.

### Fire
23. [Fire damage] "Burst of flames"  ->  suggest: "Burst of flames to head catches ears on fire"
      full: Burst of flames to head catches ears on fire! Yeeoww!
24. [Fire damage] "Eyebrow singed"  — no safe substring (full message is generic): Flames tickle right eye. Eyebrow singed.
25. [Fire damage] "Flames tickle"  ->  suggest: "Eyebrow singed"
      full: Flames tickle right eye. Eyebrow singed.
26. [Fire damage] "Forget lunch"  ->  suggest: "Flames burn neck into a bubbling mass of flesh"
      full: Flames burn neck into a bubbling mass of flesh. Forget lunch.
27. [Fire damage] "Looks painful"  ->  suggest: "Minor burns to abdomen"
      full: Minor burns to abdomen. Looks painful.
28. [Fire damage] "Looks uncomfortable"  ->  suggest: "Minor burns to neck"
      full: Minor burns to neck. Looks uncomfortable.
29. [Fire damage] "shrieks in pain"  ->  suggest: "Nasty burns to abdomen"
      full: Nasty burns to abdomen, [target] shrieks in pain!

### Impact
30. [Impact damage] "arm breaks it"  ->  suggest: "Strong blow to"
      full: Strong blow to right arm breaks it!
31. [Impact damage] "Blow connects"  — no safe substring (full message is generic): Blow connects right below right eye!
32. [Impact damage] "Blow removes"  ->  suggest: "Massive blow removes the"
      full: Massive blow removes the [target]'s right forearm at the elbow!
33. [Impact damage] "Brushing blow"  ->  suggest: "Brushing blow to temple"
      full: Brushing blow to temple.
34. [Impact damage] "eye destroys it"  — no safe substring (full message is generic): Blow to right eye destroys it!
35. [Impact damage] "Fingernail chipped"  ->  suggest: "Fingernail chipped on"
      full: Fingernail chipped on right hand.
36. [Impact damage] "hand breaks it"  ->  suggest: "Strong blow to"
      full: Strong blow to right hand breaks it!
37. [Impact damage] "Hard to breathe"  ->  suggest: "Hard blow to chest breaking ribs"
      full: Hard blow to chest breaking ribs! Hard to breathe!
38. [Impact fatal] "in his tracks"  ->  suggest: "Massive blow to temple drops the"
      full: Massive blow to temple drops the [target] in his tracks!
39. [Impact damage] "leg breaks it"  ->  suggest: "Strong blow to"
      full: Strong blow to right leg breaks it!
40. [Impact damage] "Something snaps"  ->  suggest: "Good blow to neck"
      full: Good blow to neck! Something snaps!

### Non-corporeal
41. [Non-corporeal damage] "Misjudged timing"  ->  suggest: "You barely catch the"
      full: Misjudged timing. You barely catch the [target] in the back!

### Plasma
42. [Plasma damage] "for an instant"  ->  suggest: "Burst of brilliant energy to head stuns the"
      full: Burst of brilliant energy to head stuns the [target] for an instant.
43. [Plasma damage] "Insignificant burns"  ->  suggest: "Insignificant burns to the"
      full: Insignificant burns to the [target]'s neck.
44. [Plasma damage] "spinal column"  ->  suggest: "Skin roasted away from back exposing the"
      full: Skin roasted away from back exposing the [target]'s spinal column!

### Puncture
45. [Puncture damage] "Minor puncture"  ->  suggest: "Minor puncture to the chest"
      full: Minor puncture to the chest.
46. [Puncture fatal] "quite nicely"  ->  suggest: "Strike to abdomen skewers the"
      full: Strike to abdomen skewers the [target] quite nicely!
47. [Puncture damage] "Slash across"  — no safe substring (full message is generic): Slash across right eye! Hope the left is working.
48. [Puncture damage] "sternum breaks"  ->  suggest: "Loud *crack* as the"
      full: Loud *crack* as the [target]'s sternum breaks!

### Slash
49. [Slash damage] "Barely nicked"  ->  suggest: "Light slash to the"
      full: Light slash to the [target]'s abdomen!  Barely nicked.
50. [Slash damage] "Blow to head"  — no safe substring (full message is generic): Blow to head!
51. [Slash damage] "Bone is chipped"  ->  suggest: "Deft slash to the"
      full: Deft slash to the [target]'s left leg digs deep!  Bone is chipped!
52. [Slash damage] "From the inside"  ->  suggest: "Several inches of padding   sliced off hip"
      full: Deep slash to the [target]'s right side!  Several inches of padding   sliced off hip....  From the inside!
53. [Slash damage] "Glancing slash"  ->  suggest: "Glancing slash to the"
      full: Glancing slash to the [target]'s shield arm!
54. [Slash damage] "Grazing slash"  ->  suggest: "When blood gets in your eyes"
      full: Grazing slash to the [target]'s face!  Scratch to its eyelids.  "When blood gets in your eyes..."
55. [Slash damage] "hand cuts deep"  ->  suggest: "Strong slash to the"
      full: Strong slash to the [target]'s right hand cuts deep.
56. [Slash damage] "Hesitant slash"  ->  suggest: "Hesitant slash to the"
      full: Hesitant slash to the [target]'s upper right arm!  Just a scratch.

### Steam
57. [Steam damage] "a li'l steamed"  ->  suggest: "Hot burst to to neck leaves the"
      full: Hot burst to to neck leaves the [target] a li'l steamed!
58. [Steam damage] "Mist envelops"  ->  suggest: "Mist envelops the"
      full: Mist envelops the [target]'s back.  Made it sweat.
59. [Steam damage] "R3 Back/Nerves"  — no safe substring (full message is generic): R3 Back/Nerves

### Unbalance
60. [Unbalance damage] "Broken fingernail"  ->  suggest: "How disastrous"
      full: Broken fingernail! How disastrous.
61. [Unbalance damage] "clutches stomach"  — no safe substring (full message is generic): Vertigo! The [target] clutches stomach.
62. [Unbalance damage] "Elbow wrenched"  — no safe substring (full message is generic): Elbow wrenched.
63. [Unbalance damage] "Finger broken"  — no safe substring (full message is generic): Right hand slammed. Finger broken!
64. [Unbalance damage] "Jarring blow"  ->  suggest: "Jarring blow to the"
      full: Jarring blow to the [target]'s weapon arm.
65. [Unbalance damage] "Kneecap wrenched"  — no safe substring (full message is generic): Pop! Kneecap wrenched.
66. [Unbalance damage] "Minor lumbago"  — no safe substring (full message is generic): Tickled the [target]'s back muscles. Minor lumbago.
67. [Unbalance damage] "momentary dizziness"  ->  suggest: "Strike to forehead causes the"
      full: Strike to forehead causes the [target] momentary dizziness.
68. [Unbalance damage] "Slight twitching"  ->  suggest: "Slight twitching in the"
      full: Slight twitching in the [target]'s weapon arm.
69. [Unbalance damage] "Spun counterclockwise"  ->  suggest: "Spun counterclockwise, the"
      full: Spun counterclockwise, the [target] falls in a heap.

### Vacuum
70. [Vacuum damage] "Attention getter"  — no safe substring (full message is generic): Attention getter.
71. [Vacuum damage] "Ears pop loudly"  — no safe substring (full message is generic): Ears pop loudly!
72. [Vacuum damage] "Fingernail cracks"  — no safe substring (full message is generic): Fingernail cracks!
73. [Vacuum damage] "Fingernail explodes"  — no safe substring (full message is generic): Fingernail explodes!
74. [Vacuum damage] "howls in pain"  ->  suggest: "Eye bursts, the"
      full: Eye bursts, the [target] howls in pain!
75. [Vacuum damage] "Stomach distends"  ->  suggest: "Stomach distends and the"
      full: Stomach distends and the [target] coughs up blood!