#Requires >= AutoHotkey v2.0.19

global Version := "1.0.0"

class Tween {
    static active := Map()
    static timerRunning := false
    
    __New(targetObj, goalTable, duration := 1000, easing := "Linear", callback := "") {
        if !IsObject(goalTable) || goalTable.Type != "Map"
            throw Error("Expected a Map of property goals.")

        this.target := targetObj
        this.goals := Map()
        this.startValues := Map()
        this.deltas := Map()
        this.duration := duration
        this.easing := easing
        this.callback := callback
        this.startTime := A_TickCount

        for prop, goal in goalTable {
            try this.startValues[prop] := targetObj.%prop%
            catch
                throw Error("Property '" prop "' does not exist on target.")

            this.goals[prop] := goal
            this.deltas[prop] := goal - this.startValues[prop]

            key := ObjPtr(targetObj) "|" prop
            if Tween.active.Has(key)
                Tween.active.Delete(key)
            Tween.active[key] := this
        }

        if !Tween.timerRunning {
            SetTimer Tween._UpdateAll, 10
            Tween.timerRunning := true
        }
    }

    Cancel() => this._Finish(true)

    _Finish(force := false) {
        for prop in this.goals {
            key := ObjPtr(this.target) "|" prop
            Tween.active.Delete(key)

            if !force
                this.target.%prop% := this.goals[prop]
        }

        if !force && IsFunc(this.callback)
            this.callback.Call()

        if Tween.active.Count = 0 {
            SetTimer Tween._UpdateAll, 0
            Tween.timerRunning := false
        }
    }

    static CancelTween(targetObj, propName := "") {
        if propName != "" {
            key := ObjPtr(targetObj) "|" propName
            if Tween.active.Has(key)
                Tween.active[key]._Finish(true)
        } else {
            for key, tweenFound in Tween.active.Clone() {
                if InStr(key, ObjPtr(targetObj) "|")
                    tweenFound._Finish(true)
            }
        }
    }

    static _UpdateAll() {
        now := A_TickCount
        seen := Map()

        for key, tweenFound in Tween.active.Clone() {
            if seen.Has(tweenFound)
                continue

            elapsed := now - tweenFound.startTime
            if elapsed >= tweenFound.duration {
                tweenFound._Finish()
                continue
            }

            ; check tween.duration, easing, startValues, deltas, and goals exist
            if !tweenFound.Has("duration") || !tweenFound.Has("easing") || !tweenFound.Has("startValues") || !tweenFound.Has("deltas") || !tweenFound.Has("goals")
                continue

            progress := elapsed / tweenFound.duration
            eased := Tween.ApplyEasing(progress, tweenFound.easing)

            for prop, startVal in tweenFound.startValues {
                tweenFound.target.%prop% := startVal + (tweenFound.deltas[prop] * eased)
            }

            seen[tweenFound] := true
        }
    }

    static ApplyEasing(t, mode) {
        PI := 3.14159265
        switch mode {
            case "Linear":       return t
            case "InSine":       return 1 - Cos((t * PI) / 2)
            case "OutSine":      return Sin((t * PI) / 2)
            case "InOutSine":    return -(Cos(PI * t) - 1) / 2
            case "InQuad":       return t * t
            case "OutQuad":      return 1 - (1 - t) * (1 - t)
            case "InOutQuad":    return t < 0.5 ? 2 * t * t : 1 - ((-2 * t + 2) ** 2) / 2
            default:             return t
        }
    }
}

IsFunc(obj) {
	if (obj is Func) {
		return true
	} else if (obj is String) {
		; Check if the string is a valid function name
		return IsFunc(obj)
	} else {
		return false
	}
}