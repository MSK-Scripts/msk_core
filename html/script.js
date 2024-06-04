var isInputOpen = false
var isNumpadOpen = false

/* ----------------
General Stuff 
---------------- */

$(document).ready(function() {
    window.addEventListener('message', (event) => {
        const data = event.data
    
        if (data.action == 'notify') {
            notification(data.title, data.message, data.info, data.time);
        } else if (data.action == 'openInput') {
            isInputOpen = true
            var input = 'small-input'
    
            if (data.field) {
                input = 'big-input'
                field = true
                $("#big-input").show()
                $("#small-input").hide()
            } else {
                field = false
                $("#big-input").hide()
                $("#small-input").show()
            }
    
            document.getElementById(input).placeholder = data.placeholder;
            $(".msk-input-container").fadeIn()
            $("#msk-input-title").text(data.header)
    
            document.getElementById('small-input').addEventListener("keydown", function(e) {
                if (e.key === "Enter") {
                    if (e.shiftKey) {
                        return;
                    }
                    e.preventDefault();
                }
            })
        } else if (data.action == 'closeInput') {
            closeInput();
        } else if (data.action == 'progressBarStart') {
            progressBarStart(data);
        } else if (data.action == 'progressBarStop') {
            progressBarStop();
        } else if (data.action == 'openNumpad') {
            openNumpad(data);
        } else if (data.action == 'closeNumpad') {
            closeNumpad();
        }
    })
})

document.onkeydown = function(e) {
    if (e.key === "Escape") {
        if (isInputOpen) {
            closeInput(true)
        }

        if (isNumpadOpen) {
            closeNumpad(true)
        }
    }
};

function playSound(sound, volume) {
    var audio = new Audio(`./sounds/${sound}`);
    audio.volume = volume;
    audio.play();
}

/* ----------------
MSK Notification 
---------------- */

const icons = {
    "general" : "fas fa-warehouse",
    "info"    : "fas fa-info-circle",
    "success" : "fas fa-check-circle",
    "error"   : "fas fa-exclamation-circle",
    "warning" : "fas fa-exclamation-triangle"
}

const colours = {
    "general" : "#FFFFFF",
    "info"    : "#75D6FF",
    "success" : "#76EE62",
    "error"   : "#FF4A4A",
    "warning" : "#FFCB11"
}

const colors = {
    "~r~": "red",
    "~b~": "#378cbf",
    "~g~": "green",
    "~y~": "yellow",
    "~p~": "purple",
    "~c~": "grey",
    "~m~": "#212121",
    "~u~": "black",
    "~o~": "orange"
}

const replaceColors = (str, obj) => {
    let strToReplace = str;

    for (let id in obj) {
        strToReplace = strToReplace.replace(new RegExp(id, "g"), obj[id]);
    }

    return strToReplace
}

notification = (title, message, info, time) => {
    for (color in colors) {
        if (message.includes(color)) {
            let obj = {};

            obj[color] = `<span style='color: ${colors[color]}'>`;
            obj['~s~'] = '</span>';

            message = replaceColors(message, obj);
        }
    }

    const notification = $(`
        <div class="notify-div wrapper" style="border-left: 0.5vh solid ${colours[info]}; ">
            <div class="notify-icon-box" style="border: 0.2vh solid ${colours[info]};">
                <i class="${icons[info]} fa-ms notify-icon" style="color: ${colours[info]}"></i>
            </div>

            <div class="notify-text-box">
                <p style="color:${colours[info]}; font-size: 2vh; font-weight: 500; margin-bottom: 0vh; margin-top: 1vh;">${title}</p>
                <p style="margin-top: 0; color: rgba(247, 247, 247, 0.75);">${message}</p>
            </div>
        </div>
    `).appendTo(`.notify-wrapper`);

    notification.fadeIn("slow");
    playSound("notification.mp3", 0.25);

    setTimeout(() => {
        notification.fadeOut("slow");
    }, time);

    return notification;
}

/* ----------------
MSK Input 
---------------- */

var field = false 

closeInput = (send) => {
    isInputOpen = false
    $(".msk-input-container").fadeOut("fast")
    $('#small-input').val('');
    $('#big-input').val('');
    if (send) { $.post(`https://${GetParentResourceName()}/closeInput`) }
}

submitInput = () => {
    var textfield = '#small-input'
    if (field) {textfield = '#big-input'}
    $.post(`https://${GetParentResourceName()}/submitInput`, JSON.stringify({input: $(textfield).val()}));
    closeInput()
}

/* ----------------
MSK ProgressBar 
---------------- */

let progressId = 0
let progressTimeout
let activeBars = new Map();

progressBarStart = (data) => {
    let currId = progressId
    let time = data.time
    let text = data.text
    let color = data.color

    if (!activeBars.has(currId)) {
        let progressBar = {
            element: $('#progress'),
            elementValue: $('#progress-value'),
            elementText: $('#progress-text')
        };
        activeBars.set(currId, progressBar);

        progressBar.element.removeClass('progress-hidden');
        progressBar.elementValue.css("animation",`load ${time / 1000}s normal forwards`);
        progressBar.elementText.text(text);
        document.querySelector('.progress-container').style.setProperty('--mainColor', color);
        
        progressTimeout = setTimeout(() => {
            progressBarStop(currId);
        }, time);
    }
}

progressBarStop = (id) => {
    clearTimeout(progressTimeout);
    let currId = id
    if (!id) {currId = progressId}
    let progressBar = activeBars.get(currId);
    
    if (progressBar) {
        progressBar.element.addClass('progress-hidden');
        progressBar.elementValue.css("animation",'');
        progressBar.element.css("animation",'');
        activeBars.delete(currId);
    }

    progressId = progressId + 1
}

/* ----------------
MSK Numpad 
---------------- */

var numpadCode = ''
var numpadInput = ''
var numpadLength = 4
var numpadShowPin = true
var numpadEnterCode = ''
var numpadWrongCode = ''

openNumpad = (data) => {
    isNumpadOpen = true
    numpadCode = data.code
    numpadLength = data.length
    numpadShowPin = data.show
    numpadEnterCode = data.EnterCode
    numpadWrongCode = data.WrongCode

    $('#numpad-container').fadeIn();
    $('#numpad-display').text(data.EnterCode);
    $('#numpad-wrong').text(data.WrongCode);
}

clearNumpad = () => {
    playSound("click.mp3", 0.14);
    $('#numpad-display').css('color', '#c0c0c0')
    $('#numpad-display').text(numpadEnterCode)
    numpadInput = '';
}

closeNumpad = (send) => {
    isNumpadOpen = false
    numpadInput = ''
    $('#numpad-container').fadeOut();
    if (send) { $.post(`https://${GetParentResourceName()}/closeNumpad`) }
}

getLenght = () => {
    if (numpadShowPin) {
        return $("#numpad-display").text().length;
    } else {
        return $('#numpad-display').children().length;
    }
}

addNumpad = (num) => {
    if (isNaN($("#numpad-display").text())) {
        $("#numpad-display").html('')
        $('#numpad-display').css('color', '#c0c0c0')
    }

    playSound("click.mp3", 0.14);

    if (getLenght() < numpadLength) {
        if (numpadShowPin) {
            $("#numpad-display").text($("#numpad-display").text() + num)
            numpadInput = numpadInput + num
        } else {
            $("#numpad-display").html($("#numpad-display").html()+'<i class="fa-solid fa-star-of-life"></i>') 
            numpadInput = numpadInput + num
        }
    }
}

submitNumpad = () => {
    if (numpadInput == numpadCode) {
        $.post(`https://${GetParentResourceName()}/submitNumpad`);
        closeNumpad()
    } else {
        $('#numpad-display').css('color', 'red')
        $('#numpad-display').text(numpadWrongCode)
        numpadInput = ''
    }
}