# Monash Time Travel AVP
                                             
                                    
<img width="100" height="100" alt="image" src="https://github.com/user-attachments/assets/538c3233-8f93-4f33-b242-0fa418f2eb23" />

<img width="2732" height="2048" alt="image" src="https://github.com/user-attachments/assets/33b9c85b-6450-45d1-b6e1-dfd356697956" />

(Test Scene)
<img width="2732" height="2048" alt="image" src="https://github.com/user-attachments/assets/057e86b7-56ee-4e3a-8a13-0f47fffa7241" />


Monash Time Travel AVP is an Apple Vision Pro and desktop prototype exploring how immersive spatial computing can present Monash University Clayton across deep time, travelling from 2026 back to 10000 BC.

The project began on 10 March 2026 and is being built under [Monash Nexus of Emerging Technology](https://monashemerging.tech/), an IT team at Monash University Clayton. It is being developed in collaboration with the MVIS Lab at Monash, using Apple Vision Pro equipment and technical guidance. The portfolio lead for the project is Kenneth Law.

Relevant organisation links:

- [Monash Nexus of Emerging Technology](https://monashemerging.tech/)
- [Monash Nexus of Emerging Technology on Instagram](https://www.instagram.com/monashemergingtech/)

## Scope

This project is a time-travel experience designed to let a user:

- enter an immersive Monash environment on Apple Vision Pro
- select key Monash Clayton destinations
- scrub through time from the contemporary campus back to pre-settlement terrain
- preview how architecture, landscape, and spatial storytelling may change across eras
- test interaction, scene loading, and UX patterns before final production assets are introduced

At the current stage, the experience includes:

- a time-travel menu and chronoline UI
- a non-linear time slider with modern-era emphasis and snap points
- support for multiple destination scenes:
  - Campus Centre
  - LTB
  - Alan Finkel Building
  - Lemon Scented Lawn
- placeholder geometry for scene prototyping
- immersive Vision Pro presentation and a desktop runtime for iteration
- a per-scene asset structure for replacing placeholders with final models

## Project Organisation

The codebase is organised to separate app entry, UI, gameplay logic, RealityKit systems, and content assets.

### Core folders

- `Monash Time Travel AVP/App`
  App entry points and scene registration.
- `Monash Time Travel AVP/Views`
  Main SwiftUI views for the desktop and shared interface.
- `Monash Time Travel AVP/Views/Immersive`
  visionOS immersive-space views and presentation logic.
- `Monash Time Travel AVP/Views/Menu`
  Start menu and journey-selection UI.
- `Monash Time Travel AVP/Views/Shared`
  Reusable controls, including the time-travel interface.
- `Monash Time Travel AVP/Core/Gameplay`
  Player movement, input handling, and runtime gameplay behaviour.
- `Monash Time Travel AVP/Core/TimeTravel`
  Scene selection, year mapping, timeline behaviour, and experience configuration.
- `Monash Time Travel AVP/Reality`
  RealityKit helpers, environment management, and supporting scene entities.
- `Monash Time Travel AVP/Resources/Environment`
  Shared environment resources such as visible sky imagery.
- `Monash Time Travel AVP/Resources/Scenes`
  Scene-specific asset folders for each Monash location.

### Scene asset folders

Each destination has its own asset folder so production models, textures, audio, references, and future metadata can be stored in a predictable place:

- `Monash Time Travel AVP/Resources/Scenes/Campus Centre`
- `Monash Time Travel AVP/Resources/Scenes/LTB`
- `Monash Time Travel AVP/Resources/Scenes/Alan Finkel Building`
- `Monash Time Travel AVP/Resources/Scenes/Lemon Scented Lawn`

## Current Direction

The present build is a working prototype focused on interaction design, spatial storytelling, and technical validation. Placeholder scenes are being used where needed so the team can refine the time-travel UX first, then progressively replace them with accurate Monash campus content and historical reconstructions.

## Acknowledgement

This work sits within Monash University Clayton's emerging technology portfolio, combining IT delivery, immersive hardware access, and spatial prototyping to explore how campus history can be experienced rather than simply viewed.
