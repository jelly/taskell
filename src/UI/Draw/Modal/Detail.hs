{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}

module UI.Draw.Modal.Detail
    ( detail
    ) where

import ClassyPrelude

import Control.Lens ((^.))

import Data.Sequence (mapWithIndex)

import Brick

import Data.Time.Zones (TZ)

import           Data.Taskell.Date         (deadline, timeToDisplay)
import qualified Data.Taskell.Subtask      as ST (Subtask, complete, name)
import           Data.Taskell.Task         (Task, description, due, name, subtasks)
import           Events.State              (getCurrentTask)
import           Events.State.Modal.Detail (getCurrentItem, getField)
import           Events.State.Types        (time, timeZone)
import           Events.State.Types.Mode   (DetailItem (..))
import           UI.Draw.Field             (Field, textField, widgetFromMaybe)
import           UI.Draw.Types             (DrawState (..), ModalWidget, TWidget)
import           UI.Theme                  (disabledAttr, dlToAttr, taskCurrentAttr,
                                            titleCurrentAttr)

renderSubtask :: Maybe Field -> DetailItem -> Int -> ST.Subtask -> TWidget
renderSubtask f current i subtask = padBottom (Pad 1) $ prefix <+> final
  where
    cur =
        case current of
            DetailItem c -> i == c
            _            -> False
    done = subtask ^. ST.complete
    attr =
        withAttr
            (if cur
                 then taskCurrentAttr
                 else titleCurrentAttr)
    prefix =
        attr . txt $
        if done
            then "[x] "
            else "[ ] "
    widget = textField (subtask ^. ST.name)
    final
        | cur = visible . attr $ widgetFromMaybe widget f
        | not done = attr widget
        | otherwise = widget

renderSummary :: Maybe Field -> DetailItem -> Task -> TWidget
renderSummary f i task = padTop (Pad 1) $ padBottom (Pad 2) w'
  where
    w = textField $ fromMaybe "No description" (task ^. description)
    w' =
        case i of
            DetailDescription -> visible $ widgetFromMaybe w f
            _                 -> w

renderDate :: TZ -> UTCTime -> Maybe Field -> DetailItem -> Task -> TWidget
renderDate tz now field item task =
    case item of
        DetailDate -> visible $ prefix <+> widgetFromMaybe widget field
        _ ->
            case day of
                Just d  -> prefix <+> withAttr (dlToAttr (deadline now d)) widget
                Nothing -> emptyWidget
  where
    day = task ^. due
    prefix = txt "Due: "
    widget = textField $ maybe "" (timeToDisplay tz) day

detail :: ModalWidget
detail = do
    state <- asks dsState
    let now = state ^. time
    let tz = state ^. timeZone
    pure $
        fromMaybe ("Error", txt "Oops") $ do
            task <- getCurrentTask state
            i <- getCurrentItem state
            let f = getField state
            let sts = task ^. subtasks
                w
                    | null sts = withAttr disabledAttr $ txt "No sub-tasks"
                    | otherwise = vBox . toList $ renderSubtask f i `mapWithIndex` sts
            pure (task ^. name, renderDate tz now f i task <=> renderSummary f i task <=> w)
