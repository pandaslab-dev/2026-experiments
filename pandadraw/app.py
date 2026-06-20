import tkinter as tk
from tkinter import filedialog
import sys

WINDOW_BLUE = "#d8e7f8"
PANEL_BLUE = "#c6d9f1"
MENU_BG = "#f3f1e8"
STATUS_BG = "#ece9d8"
BORDER = "#7f9db9"
BUTTON_BG = "#f7f7f7"
BUTTON_ACTIVE = "#e7eef8"
TEXT = "#202020"


class PaintApp:
    def __init__(self, root):
        self.root = root
        self.root.title("untitled - Paint")
        self.root.geometry("900x600")
        self.root.configure(bg=WINDOW_BLUE)

        self.current_tool = "pencil"
        self.current_color = "#000000"
        self.brush_size = 4

        self.last_x = None
        self.last_y = None
        self.tool_buttons = {}
        self.color_swatches = []

        self.build_ui()

    def build_ui(self):
        self.make_menu_bar()
        self.make_toolbar()
        self.make_main_area()
        self.make_status_bar()

    def make_menu_bar(self):
        menu_bar = tk.Frame(self.root, bg=MENU_BG, bd=1, relief="raised")
        menu_bar.pack(fill="x")

        menu_text = "File   Edit   View   Image   Colors   Help"
        label = tk.Label(
            menu_bar,
            text=menu_text,
            bg=MENU_BG,
            fg=TEXT,
            anchor="w",
            padx=8,
            pady=4,
            font=("Tahoma", 10),
        )
        label.pack(fill="x")

    def make_toolbar(self):
        toolbar = tk.Frame(self.root, bg=PANEL_BLUE, bd=2, relief="groove")
        toolbar.pack(fill="x", padx=6, pady=(4, 2))

        for tool_name in ["Pencil", "Brush", "Eraser"]:
            button = self.make_button(
                toolbar,
                tool_name,
                lambda name=tool_name.lower(): self.set_tool(name),
                width=8,
            )
            button.pack(side="left", padx=4, pady=4)
            self.tool_buttons[tool_name.lower()] = button

        self.make_button(toolbar, "Clear", self.clear_canvas, width=8).pack(
            side="left", padx=4, pady=4
        )
        self.make_button(toolbar, "Save", self.save_drawing, width=8).pack(
            side="left", padx=4, pady=4
        )

        size_label = tk.Label(
            toolbar,
            text="Size",
            bg=PANEL_BLUE,
            fg=TEXT,
            font=("Tahoma", 10),
        )
        size_label.pack(side="left", padx=(20, 4))

        self.size_value = tk.Label(
            toolbar,
            text=str(self.brush_size),
            width=2,
            bg=PANEL_BLUE,
            fg=TEXT,
            font=("Tahoma", 10, "bold"),
        )
        self.size_value.pack(side="left", padx=(0, 6))

        self.size_scale = tk.Scale(
            toolbar,
            from_=1,
            to=20,
            orient="horizontal",
            bg=PANEL_BLUE,
            fg=TEXT,
            activebackground=PANEL_BLUE,
            highlightbackground=PANEL_BLUE,
            highlightthickness=0,
            troughcolor="#d8d8d8",
            bd=0,
            command=self.change_size,
        )
        self.size_scale.set(self.brush_size)
        self.size_scale.pack(side="left", padx=4)

    def make_main_area(self):
        main_area = tk.Frame(self.root, bg=WINDOW_BLUE)
        main_area.pack(fill="both", expand=True, padx=6, pady=4)

        self.make_toolbox(main_area)
        self.make_canvas_area(main_area)

    def make_toolbox(self, parent):
        toolbox = tk.Frame(parent, bg=PANEL_BLUE, bd=2, relief="groove", width=110)
        toolbox.pack(side="left", fill="y", padx=(0, 6))
        toolbox.pack_propagate(False)

        tk.Label(
            toolbox,
            text="Tools",
            bg=PANEL_BLUE,
            fg=TEXT,
            font=("Tahoma", 10, "bold"),
        ).pack(pady=(10, 6))

        for tool_name in ["Pencil", "Brush", "Eraser"]:
            self.make_button(
                toolbox,
                tool_name,
                lambda name=tool_name.lower(): self.set_tool(name),
                width=10,
            ).pack(pady=4)

        tk.Label(
            toolbox,
            text="Colors",
            bg=PANEL_BLUE,
            fg=TEXT,
            font=("Tahoma", 10, "bold"),
        ).pack(pady=(20, 6))

        colors = [
            "#000000",
            "#7f7f7f",
            "#800000",
            "#ff0000",
            "#808000",
            "#ffff00",
            "#008000",
            "#00ff00",
            "#008080",
            "#00ffff",
            "#000080",
            "#0000ff",
        ]

        color_box = tk.Frame(toolbox, bg=PANEL_BLUE)
        color_box.pack(pady=4)

        for index, color in enumerate(colors):
            swatch = tk.Label(
                color_box,
                bg=color,
                width=4,
                height=2,
                relief="raised",
                bd=1,
            )
            swatch.bind("<Button-1>", lambda event, chosen=color: self.set_color(chosen))
            row = index // 2
            column = index % 2
            swatch.grid(row=row, column=column, padx=4, pady=4)
            self.color_swatches.append((color, swatch))

    def make_canvas_area(self, parent):
        canvas_frame = tk.Frame(parent, bg=BORDER, bd=2, relief="sunken")
        canvas_frame.pack(side="left", fill="both", expand=True)

        self.canvas = tk.Canvas(
            canvas_frame,
            bg="white",
            width=700,
            height=450,
            cursor="crosshair",
            highlightthickness=0,
        )
        self.canvas.pack(fill="both", expand=True, padx=2, pady=2)

        self.canvas.bind("<Button-1>", self.start_draw)
        self.canvas.bind("<B1-Motion>", self.draw)
        self.canvas.bind("<ButtonRelease-1>", self.stop_draw)

    def make_status_bar(self):
        self.status_label = tk.Label(
            self.root,
            text="Tool: Pencil   Color: #000000   Size: 4",
            bg=STATUS_BG,
            fg=TEXT,
            anchor="w",
            padx=8,
            pady=4,
            font=("Tahoma", 10),
        )
        self.status_label.pack(fill="x", side="bottom")
        self.update_tool_buttons()
        self.update_color_swatches()

    def make_button(self, parent, text, command, width):
        return tk.Button(
            parent,
            text=text,
            width=width,
            command=command,
            bg=BUTTON_BG,
            fg=TEXT,
            activebackground=BUTTON_ACTIVE,
            activeforeground=TEXT,
            highlightthickness=0,
            bd=1,
            relief="raised",
            font=("Tahoma", 10),
        )

    def set_tool(self, tool_name):
        self.current_tool = tool_name
        self.update_tool_buttons()
        self.update_status()

    def set_color(self, color):
        self.current_color = color
        self.update_color_swatches()
        self.update_status()

    def change_size(self, value):
        self.brush_size = int(value)
        self.size_value.config(text=str(self.brush_size))
        self.update_status()

    def start_draw(self, event):
        self.last_x = event.x
        self.last_y = event.y

    def draw(self, event):
        if self.last_x is None or self.last_y is None:
            return

        color = self.current_color
        width = self.brush_size

        if self.current_tool == "eraser":
            color = "white"
            width = self.brush_size * 2
        elif self.current_tool == "brush":
            width = self.brush_size + 4

        self.canvas.create_line(
            self.last_x,
            self.last_y,
            event.x,
            event.y,
            fill=color,
            width=width,
            capstyle="round",
            smooth=True,
        )

        self.last_x = event.x
        self.last_y = event.y

    def stop_draw(self, event):
        self.last_x = None
        self.last_y = None

    def clear_canvas(self):
        self.canvas.delete("all")

    def save_drawing(self):
        file_path = filedialog.asksaveasfilename(
            defaultextension=".ps",
            filetypes=[("PostScript File", "*.ps")],
            title="Save Drawing",
        )

        if file_path:
            self.canvas.postscript(file=file_path)
            self.status_label.config(text=f"Saved drawing to {file_path}")

    def update_status(self):
        tool_name = self.current_tool.capitalize()
        self.status_label.config(
            text=f"Tool: {tool_name}   Color: {self.current_color}   Size: {self.brush_size}"
        )

    def update_tool_buttons(self):
        for tool_name, button in self.tool_buttons.items():
            if tool_name == self.current_tool:
                button.config(relief="sunken", bg=BUTTON_ACTIVE)
            else:
                button.config(relief="raised", bg=BUTTON_BG)

    def update_color_swatches(self):
        for color, swatch in self.color_swatches:
            if color == self.current_color:
                swatch.config(relief="sunken", bd=2)
            else:
                swatch.config(relief="raised", bd=1)


def main():
    if "Xcode.app" in sys.executable:
        print("this app uses tkinter for the window.")
        print("the python that comes from xcode is crashing before tkinter can open.")
        print("try running this with a different python build, such as:")
        print("- python from python.org")
        print("- python from homebrew")
        print("")
        print("example after installing another python:")
        print("python3 app.py")
        return

    root = tk.Tk()
    PaintApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
