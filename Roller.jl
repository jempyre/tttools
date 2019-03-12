module WoDRoller
import Pkg

macro require(pkg...)
    for p in pkg
        try Pkg.installed()["$p"]
        catch KeyError
            Pkg.add("$p")
        end
    end
end

@require Interact Blink

"""
    **roll**(_n_::__Int__)
    _Return_s a number of successful rolls out of `n` rolls in accordance
    with the rules presented in [Vampire: The Masquerade _Fifth Edition_]
    (https://www.worldofdarkness.com).
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

"""
    **roll**(_n_::__Int__, _targ_::__Int__)
    _Return_s a __margin of success__ from `n` rolls vs. a difficulty of `targ`
    in accordance with the rules presented in [Vampire: The Masquerade _Fifth Edition_]
    (https://www.worldofdarkness.com).
"""
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
