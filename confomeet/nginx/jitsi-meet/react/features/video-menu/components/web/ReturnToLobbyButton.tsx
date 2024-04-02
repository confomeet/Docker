import React, { useCallback } from "react";
import { useDispatch } from "react-redux";
import ContextMenuItem from "../../../base/ui/components/web/ContextMenuItem";
import { IconUserDeleted } from "../../../base/icons/svg";
import { IButtonProps } from "../../types";
import { NOTIFY_CLICK_MODE } from "../../../toolbox/types";
import { returnParticipantToLobby } from "../../../base/participants/actions";
import { useTranslation } from "react-i18next";

const ReturnToLobbyButton = ({
    notifyClick,
    notifyMode,
    participantID
}: IButtonProps): JSX.Element => {
    const dispatch = useDispatch();
    const { t } = useTranslation();

    const handleClick = useCallback(() => {
        notifyClick?.();
        if (notifyMode == NOTIFY_CLICK_MODE.PREVENT_AND_NOTIFY) {
            return;
        }
        dispatch(returnParticipantToLobby(participantID));
    }, [ notifyClick, notifyMode, participantID ]);

    return (
        <ContextMenuItem
            accessibilityLabel = { t("videothumbnail.returnToLobby") }
            className = "returnToLobbyLink"
            icon = { IconUserDeleted }
            id = { `returnToLobbyLink_${participantID}` }
            onClick = { handleClick }
            text = { t("videothumbnail.returnToLobby") } />
    )
};

export default ReturnToLobbyButton;
