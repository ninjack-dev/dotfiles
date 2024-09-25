import { Bar } from "./bar.js"

App.config({
    style: "./style.css",
    windows: [
        Bar(0),
        Bar(1),

        // you can call it, for each monitor
        // Bar(0),
        // Bar(1)
    ],
})
