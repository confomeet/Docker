// @flow

import { openDialog } from '../../base/dialog';
import { IconLobby } from '../../base/icons';
import { AbstractButton, type AbstractButtonProps } from '../../base/toolbox/components';

import { KickToLobbyDialog } from '.';

export type Props = AbstractButtonProps & {

    /**
     * The redux {@code dispatch} function.
     */
    dispatch: Function,

    /**
     * The ID of the participant that this button is supposed to kick.
     */
    participantID: string,

    /**
     * The function to be used to translate i18n labels.
     */
    t: Function
};

/**
 * An abstract remote video menu button which kicks the remote participant back to lobby.
 */
export default class AbstractKickToLobbyButton extends AbstractButton<Props, *> {
    accessibilityLabel = 'toolbar.accessibilityLabel.kick';
    icon = IconLobby;
    label = 'videothumbnail.kickToLobby';

    /**
     * Handles clicking / pressing the button, and kicks the participant back to lobby.
     *
     * @private
     * @returns {void}
     */
    _handleClick() {
        const { dispatch, participantID } = this.props;

        dispatch(openDialog(KickToLobbyDialog, { participantID }));
    }
}
