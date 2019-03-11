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

function composeui()
    dice = input(3; typ="number")
    target = input(3; typ="number")
    rollnow = button("Roll!")
    dicel = hbox("Dice to Roll:", dice)
    targl = hbox("Success Need:", target)
    roller = vbox(dicel, targl, rollnow)
    on(n -> println(roll(dice[], target[])), rollnow)
end

# compose the UI
try using Interact
    composeui()
catch ArgumentError
    import Pkg; Pkg.add("Interact")
    using Interact
    composeui()
end

function showwin()
    w = Window()
    body!(w, roller)
end

try using Blink
    showwin()
catch ArgumentError
    import Pkg; Pkg.add("Blink")
    showwin()
end
