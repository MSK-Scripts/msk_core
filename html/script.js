var field = false 

window.addEventListener('message', (event) => {
    if (event.data.action == 'notify') {
        notification(event.data.title, event.data.message, event.data.info, event.data.time);
    } else if (event.data.action == 'openInput') {
        var data = event.data;
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
    } else if (event.data.action == 'progressBarStart') {
        progressBarStart(event.data);
    } else if (event.data.action == 'progressBarStop') {
        progressBarStop(event.data.id);
    }
})

/* MSK Notification */

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

var sound = new Audio('notification.mp3');
sound.volume = 0.25;

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
    sound.play();

    setTimeout(() => {
        notification.fadeOut("slow");
    }, time);

    return notification;
}

/* MSK Input */

closeInputUI = (send) => {
    $(".msk-input-container").fadeOut()
    if (!send) { $.post(`http://${GetParentResourceName()}/closeInput`, JSON.stringify({})) }
}

document.onkeyup = (data) => {
    if (data.which == 27) {
        closeInputUI()
    }
}

$("#small-input").keydown((event) => {
    if (event.keyCode == 13) {
        event.preventDefault();
    }
})

input = () => {
    var textfield = '#small-input'
    if (field) {textfield = '#big-input'}

    $.post(`http://${GetParentResourceName()}/submitInput`, JSON.stringify({input: $(textfield).val()}));
    $(textfield).val('');
    closeInputUI(true)
}

/* MSK ProgressBar */

let activeBars = new Map(); // Using a Map to store active bars with their IDs as keys
let isProgressActive = false

progressBarStart = (data) => {
    if (activeBars.has(data.id)) {
        $.post(`https://${GetParentResourceName()}/notif`, JSON.stringify({ text: "Already doing an action." }));
        return;
    }

    let progressBar = {
        element: $('#progress'),
        elementValue: $('#progress-value')
    };

    activeBars.set(data.id, progressBar);

    progressBar.element.removeClass('hidden');
    progressBar.elementValue.css("animation",`load ${data.time}s normal forwards`);
    progressBar.element.css("animation",`glow ${data.time}s normal forwards`);
    
    $('#progress-text').text(data.text);
    document.body.style.setProperty('--mainColor', data.color);

    setTimeout(() => {
        stopProgress(data.id);
    }, data.time);
}

progressBarStop = (id) => {
    let progressBar = activeBars.get(id);
    
    if (progressBar) {
        progressBar.element.addClass('hidden');
        progressBar.elementValue.css("animation",'');
        progressBar.element.css("animation",'');
        activeBars.delete(id);
    }
}