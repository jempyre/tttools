"""
`Require` is a middle-ware for pkg management above the `Pkg` module.
"""
module Require
import Pkg

export @require

"""
`@require` installs packages that are passed to it if they are not currently
registered.

!!! note
    Currently does not check version strings.
"""
macro require(pkg...)
    for p in pkg
        try Pkg.installed()["$p"]
        catch KeyError
            Pkg.add("$p")
        end
    end
end
end

"""
Roller is the base module for the dice rolling functions.
"""
module Roller

"""
`WoDRoller` throws virtual dice to resolve tests in accordance with the rules
from the [Vampire: The Masquerade _Fifth Edition_]
(https://www.worldofdarkness.com).
"""
module WoDRoller
import Main.Require; Require.@require Interact Blink;

"""
    roll(n [, targ])
`Return` a number of successful rolls out of `n` rolls in accordance
with the rules presented in [Vampire: The Masquerade _Fifth Edition_]
(https://www.worldofdarkness.com).

If _targ_ is supplied, `return` a __margin of success__ instead.

# Paramaters
- `n::Integer`: The number of dice to roll, i.e. the _Player Character's_ skill level.
- `targ::Integer`: The _target_ number of successes required. Will `return` a _margin of success_.

# Examples
```jldoctest
julia>rng = MersenneTwister(1234); #TODO need to pass seed to roll().

julia>

```
"""
function roll(n::Int)
    R = rand(1:10, n)
    suc = 0
    crits = 0

    # give a success for 6:9, and a potential crit for 10
    for r in R
        if 6 ≤ r < 10
            suc += 1
        elseif r == 10
            if crits == 1
                suc += 4
                crits = 0
            elseif crits == 0
                crits = 1
            end
        end
    end

    # check for odd crits
    if crits > 0
        crits -= 1
        suc += 1
    end

    return suc
end

roll(n::Int, targ::Int) = roll(n) - targ # returns a margin of success

# compose the UI
using Interact
dice = input(3; typ="number")
target = input(3; typ="number")
rollnow = button("Roll!")
dicel = hbox("Dice to Roll:", dice)
targl = hbox("Success Need:", target)
roller = vbox(dicel, targl, rollnow)
on(n -> println(roll(dice[], target[])), rollnow)
using Blink
w = Window()
body!(w, roller)
end

"""
`EPRoller` throws virtual dice to resolve tests in near accordance with the rules
from the [Eclipse Phase 2e Playtest ruleset](www.eclipsephase.com).

!!! note
    this code may be considered _opinionated_. See below for details.

# Opinionated Code
Rather than follow the **RAW** precisely, we make a few shortcuts that may be
important to you.

## Settling Ties
In a contest ties are settled by comparing the _Character_s
*final target difficulty* rather than their *base* skill values. Our opinion
is that the **RAW** mistakenly ignores environmental factors when settling a tie,
and this is especially important to our code-base because it actually costs
more to get the **RAW** authorized `return`.ex
"""
module EPRoller

"`TestResult` stuctures the data resulting from `EPRoller` functions."
struct TestResult
    roll::Integer
    success::Boolean
    magnitude::Integer
    crit::Boolean
end

"""
    quicktest(target) performs a _d100_ roll against the `target`.

The resulting `TestResult` is built according to the
[Eclipse Phase](www.eclipsephase.com) __2nd Edition Playtest__ rules, _mostly_.

!!! note
    See [Roller.EPRoller](@ref)
# Parameters
- `target::Integer`: The target value to roll under.
"""
function quicktest(target::Int)
    roll = rand(0:99)
    success = false
    magnitude = 0
    crit = false

    # check for success
    if roll ≤ target
        success = true
    end

    # check for superior results
    if success && roll ≥ 33
        magnitude += 1
        if roll ≥ 66
            magnitude += 1
        end
    elseif roll ≤ 66
        magnitude += 1
        if roll ≤ 33
            magnitude += 1
        end
    end

    # check for crits
    if (roll ÷ 10) == (roll % 10)
        crit = true
    end

    # check for auto crits
    if (roll == 0)
        success = true
        crit = true
    elseif roll == 99
        success = false
        crit = true
    end

    return TestResult(roll, success, magnitude, crit)
end

"""
    **opposedtest**(_targ1_::__Int__, _targ2_::__Int__) performs a `quicktest()`
        on each `targ`, comparing the resultant `TestResult`s in accordance with
        the [Eclipse Phase](www.eclipsephase.com) __2nd Edition Playtest__ rules.
"""
function opposedtest(targ1::Int, targ2::Int)
    test1 = quicktest(targ1)
    test2 = quicktest(targ2)
    secondplayerwins = false # false implies that the first player defaults as winner

    function checkrolls(_test1::TestResult,
                _test2::TestResult, _targ1::Int, _targ2::Int)

        if _test2.roll > _test1.roll
            return true
        elseif _test2.roll == _test1.roll # the rolls were equal
            # give the tie to the higher target
            if _targ2 > _targ1
                return true
            elseif _targ2 == _targ1 # still a tie, call recursively (as if to roll again)
                return opposedtest(_targ1, _targ2)
            end
        else
            # roll1 is higher
            return false
        end
    end

    # compare the results
    if test2.success && !test1.success
        # only the second test succeeded
        secondplayerwins = true
    elseif test2.success && test1.success
        # both succeed, so check for higher roll
        secondplayerwins = checkrolls(test1, test2, targ1, targ2)
        # check for crits to trump rolls
        if test2.crit && !test1.crit # second player has a crit
            secondplayerwins = true
        elseif test1.crit && !test2.crit
            secondplayerwins = false
        end
    elseif !test2.success && !test1.success
        secondplayerwins = checkrolls(test1, test2, targ1, targ2)
    end
    return secondplayerwins
end
end #eproller
end #roller
