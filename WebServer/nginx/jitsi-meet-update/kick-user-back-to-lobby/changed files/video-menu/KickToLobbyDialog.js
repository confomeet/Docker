// @flow

import React from 'react';

import { Dialog } from '../../../base/dialog';
import { translate } from '../../../base/i18n';
import { connect } from '../../../base/redux';
import AbstractKickToLobbyDialog
    from '../AbstractKickToLobbyDialog';

/**
 * Dialog to confirm a remote participant kick to lobby action.
 */
class KickToLobbyDialog extends AbstractKickToLobbyDialog {
    /**
     * Implements React's {@link Component#render()}.
     *
     * @inheritdoc
     * @returns {ReactElement}
     */
    render() {
        return (
            <Dialog
                okKey = 'dialog.kickToLobbyButton'
                onSubmit = { this._onSubmit }
                titleKey = 'dialog.kickToLobbyTitle'
                width = 'small'>
                <div>
                    { this.props.t('dialog.kickToLobbyDialog') }
                </div>
            </Dialog>
        );
    }

    _onSubmit: () => boolean;
}

export default translate(connect()(KickToLobbyDialog));
