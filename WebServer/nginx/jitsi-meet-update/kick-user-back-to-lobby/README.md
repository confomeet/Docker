# lang/main.json

- in dialog section add:

```markdown
        "kickToLobbyButton": "Send",
        "kickToLobbyDialog": "Are you sure you want to send this participant back to lobby?",
        "kickToLobbyTitle": "Send this participant back to lobby?",
```

- in videothumbnail section add: 

```markdown
        "kickToLobby": "Send user back to lobby",
```


# react/features/base/icons/svg/hour-glass.svg

add it in the path: /react/features/base/icons/svg

# react/features/base/icons/svg/index.js

- export it by adding this line:

```markdown
export { default as IconLobby } from './hour-glass.svg';
```

# react/features/lobby/actions.web.js

add this import:

```markdown
import {
    getCurrentConference,
} from '../base/conference';
```

- add the following function:

```markdown
/**
 * Send partcipant back to lobby.
 *
 * @param {string} id - The id of the participant.
 * @returns {Function}
 */
export function kickParticipantBackToLobby(id: string) {
    return async (dispatch: Dispatch<any>, getState: Function) => {
        const conference = getCurrentConference(getState);

        conference && conference.lobbyKickBack(id);
    };
}
```

# react/features/lobby/index.js

- export it by adding this line:

```markdown
export * from './actions';
```

# react/features/participants-pane/components/web/MeetingParticipantContextMenu.js

- add this import

```markdown
 import {IconLobby} from '../../../base/icons'
```

- add this import

```markdown
 import {KickToLobbyDialog} from '../../../video-menu'
```

- in the **constructor** add this line:

```markdown
this._onKickToLobby = this._onKickToLobby.bind(this);
```

- and add this lines after the **constructor**:

```markdown
_onKickToLobby: () => void;

    /**
     * Kicks the participant back to lobby.
     *
     * @returns {void}
     */
    _onKickToLobby() {
        const { _participant, dispatch } = this.props;

        dispatch(openDialog(KickToLobbyDialog, {
            participantID: _participant?.id
        }));
    }
```

- inside **ContextMenu** tag and the second **ContextMenuItemGroup** tag add this block after **videothumbnail.kick** block:

```markdown
        {
                !_isParticipantModerator && (
                    <ContextMenuItem onClick = { this._onKickToLobby } >
                        <ContextMenuIcon src = { IconLobby } />
                            <span>{ t('videothumbnail.kickToLobby') }</span>
                        </ContextMenuItem>
                    )
        }
```

# react/features/video-menu/components/AbstractKickToLobbyButton.js

- add the file in the path: react/features/video-menu/components

# react/features/video-menu/components/AbstractKickToLobbyDialog.js

- add the file in the path: react/features/video-menu/components

# react/features/video-menu/components/web/KickToLobbyButton.js

- add the file in the path: react/features/video-menu/components/web

# react/features/video-menu/components/web/KickToLobbyDialog.js

- add the file in the path: react/features/video-menu/components/web

# react/features/video-menu/components/web/index.js

- export the two new components 

```markdown
export { default as KickToLobbyButton } from './KickToLobbyButton';
export { default as KickToLobbyDialog } from './KickToLobbyDialog';
```

# react/features/video-menu/components/web/ParticipantContextMenu.js

- add the import *{KickToLobbyButton}* from './'

- at the end if thid condition **if (_isModerator)** add this block:

```markdown
    if (true) {
            buttons2.push(
                <KickToLobbyButton
                    key = 'kick-to-lobby'
                    participantID = { _getCurrentParticipantId() } />
            );
    }
```

# react/features/video-menu/components/web/index.js

- add this line 

```markdown
export { default as KickToLobbyDialog } from './KickToLobbyDialog';
```

# react/features/lobby/middleware.js

- add this line:

```markdown
import { reloadNow } from '../app/actions';
```

- inside **StateListenerRegistry.register** add this block:

```markdown
conference.on(JitsiConferenceEvents.KICK_BACK_TO_LOBBY_RECEIVED, () => {
                sessionStorage.setItem('autoKnockingFlag', 'true');
                dispatch(reloadNow());
        });
```

- in the condition **if (shouldAutoKnock(state))** add this line:

```markdown
sessionStorage.removeItem('autoKnockingFlag');
```

# react/features/prejoin/functions.js

- replace this line:

```markdown
return (isPrejoinPageEnabled(state) || (iAmRecorder && iAmSipGateway))
```

- with this block: 

```markdown
return (autoKnockingFlag || isPrejoinPageEnabled(state) || (iAmRecorder && iAmSipGateway))
        && !state['features/lobby'].knocking;
```


