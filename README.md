# QuickRP Forever 🎭

**QuickRP Forever** is a sleek, lightweight, and immersive roleplay dialogue and emote engine built specifically for **World of Warcraft: Forever**.

Designed with the rich antique bronze and dark mahogany aesthetics familiar to classic RP suites (such as *Total RP 3*), **QuickRP Forever** allows you to organize, trigger, and cycle through custom character emotes, spoken dialogue, and combat battle cries with zero performance overhead.

---

### ✨ Key Features

* **🎬 In-Addon Sequence Builder**: Build multi-step dialogue scenes and theatrical emote performances directly in the editor. Arrange steps with **`▲`** / **`▼`** reorder buttons, track the active **`[NEXT STEP]`** with a glowing gold highlight, and rewind anytime with **`↺ Reset to Step 1`**.
* **📁 Hierarchical Folders & Groups**: Organize your roleplay lines by **Character**, **Situation** (e.g., *Tavern Nights*, *Camping*, *Courtly Intrigue*), or **Combat**. Expand or collapse folders at will.
* **🖱️ Intuitive Drag & Drop**: Easily rearrange your groups or nest them inside parent folders by dragging them across the sidebar.
* **🎲 Random & 🔄 Sequential Playback**:
  * **Random Mode**: Spices up repetitive roleplay actions by selecting a random variation each time.
  * **Sequential Mode**: Delivers multi-line emotes, theatrical performances, or speeches in exact chronological order.
* **🏷️ Smart Name Placeholders (Tokens)**: Automatically replaces `%pf`, `%pl`, `%tf`, and `%tl` with proper first and last names of yourself and your target.
* **📡 Full Multi-Channel Support**: Seamlessly send lines to **Emote**, **Say**, **Yell**, **Party**, **Guild**, or **Raid** channels, complete with channel icons and color badges.
* **📋 Discord-Ready Import & Export**: Share roleplay packs with friends or backup your library using clean, human-readable text or compact share strings.
* **⚡ Floating Quick-Trigger Bar**: A minimalist, movable floating window for 1-click emote activation during live events, tavern gatherings, and encounters.
* **⚙️ Blizzard Options & Minimap Integration**: Fully integrated into the native Game Settings menu (`Esc -> Options -> AddOns`) with a customizable minimap button.
* **🎯 Macro Friendly**: Bind any group to your action bar or keybind with `/qrp <GroupName>`.

---

## 🏷️ Smart Name Tokens

Make your dialogue sound natural without hardcoding names. QuickRP automatically parses multi-word character names:

| Token | Replaced With | Example (Caradon Majore targeting Archdruid Hunaka) |
| :--- | :--- | :--- |
| **`%pf`** | Player First Name | `Caradon` |
| **`%pl`** | Player Last Name | `Majore` |
| **`%p`** | Player Full Name | `Caradon Majore` |
| **`%tf`** | Target First Name | `Hunaka` *(or "someone" if no target)* |
| **`%tl`** | Target Last Name | `Greenhoof` *(or "someone" if no target)* |
| **`%t`** | Target Full Name | `Archdruid Hunaka` *(or "someone" if no target)* |

#### Example Usage:
> `smiles warmly at %tf. "Well met, %tf %tl! House %pl salutes you."`

---

## 🚀 Quick Start Guide

1. **Open the Editor**: Click the QuickRP minimap icon, type `/qrp`, or navigate to **Game Menu > Options > AddOns > QuickRP Forever**.
2. **Create a Category**: Type a name in the sidebar input box, then click **`+ New Folder`** to create a parent category (e.g., `Character: Valen`) or **`+ New Text Group`** to create a phrase group (e.g., `Greetings`).
3. **Add Your Phrases**:
   * Select your group from the sidebar.
   * Choose your channel (**Emote**, **Say**, **Yell**, etc.).
   * Type your text using name tokens and press **Enter** or click **`+ Add Line`**.
4. **Choose Mode**: Toggle between **Random** and **Sequential** at the top right of the group header.
5. **Fire the Emote**:
   * Click the **`>`** Play button on any individual card.
   * Click the group button in the **Floating Quick Bar** (`/qrp win`).
   * Or macro it: `/qrp Greetings`.

---

## 📦 Import & Export System

Want to backup your dialogue lines or share a curated roleplay script with your guild or friends?

1. Click the crimson **`Import / Export`** button in the main window (or type `/qrp exp`).
2. **Export**:
   * **Readable Format**: Generates clean, formatted text with tags like `[Folder: ...]`, `[Group: ... | RANDOM]`, and `[Emote] ...` that you can directly copy-paste into Discord or notes.
   * **Compact Code**: Click **"Export as Compact Code"** to generate a single Base64 encoded string (`!QRPF:1:...`).
3. **Import**:
   * Switch to the **Import** tab to see a formatted template with `[Folder: ...]`, `[Group: ...]`, and examples of every chat channel (`[Emote]`, `[Say]`, `[Yell]`, `[Party]`, `[Guild]`, `[Raid]`).
   * Click **"Load Example Format"** to test with pre-filled dialogue, or paste your own plain text or compact `!QRPF:1:...` code.
   * Click **`Import Content Now`** to immediately import into your library.

---

## ⌨️ Slash Commands

| Command | Action |
| :--- | :--- |
| `/qrp` or `/rp` | Toggle the main QuickRP configuration window. |
| `/qrp win` | Toggle the compact floating RP trigger window. |
| `/qrp exp` | Open the dialogue pack Export utility. |
| `/qrp imp` | Open the dialogue pack Import utility. |
| `/qrp opt` | Open the Blizzard Game Settings configuration page. |
| `/qrp <GroupName>` | Triggers a phrase from `<GroupName>` (ideal for macros & keybinds). |

#### Macro Example:
```lua
#showtooltip
/qrp Greetings
```

---

## 🎨 Crafted for Immersion
QuickRP Forever was built with love for the roleplay community. It does not replace full profile suites like *Total RP 3*, but rather serves as their nimble companion—giving you instant, organized access to your character's voice when words matter most.
