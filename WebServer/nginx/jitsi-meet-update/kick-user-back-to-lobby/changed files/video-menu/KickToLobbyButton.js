/* @flow */

import React from 'react';

import ContextMenuItem from '../../../base/components/context-menu/ContextMenuItem';
import { translate } from '../../../base/i18n';
import { IconLobby } from '../../../base/icons';
import { connect } from '../../../base/redux';
import AbstractKickToLobbyButton, {
    type Props
} from '../AbstractKickToLobbyButton';


/**
 * Implements a React {@link Component} which displays a button for kicking out
 * a participant back to lobby.
 *
 * NOTE: At the time of writing this is a button that doesn't use the
 * {@code AbstractButton} base component, but is inherited from the same
 * super class ({@code AbstractKickButton} that extends {@code AbstractButton})
 * for the sake of code sharing between web and mobile. Once web uses the
 * {@code AbstractButton} base component, this can be fully removed.
 */
class KickToLobbyButton extends AbstractKickToLobbyButton {
    /**
     * Instantiates a new {@code Component}.
     *
     * @inheritdoc
     */
    constructor(props: Props) {
        super(props);

        this._handleClick = this._handleClick.bind(this);
    }

    /**
     * Implements React's {@link Component#render()}.
     *
     * @inheritdoc
     * @returns {ReactElement}
     */
    render() {
        const { participantID, t } = this.props;

        return (
            <ContextMenuItem
                accessibilityLabel = { t('videothumbnail.kickToLobby') }
                className = 'kicklink'
                icon = { IconLobby }
                id = { `to_lobby_link_${participantID}` }
                // eslint-disable-next-line react/jsx-handler-names
                onClick = { this._handleClick }
                text = { t('videothumbnail.kickToLobby') } />
        );
    }

    _handleClick: () => void
}
export default translate(connect()(KickToLobbyButton));
