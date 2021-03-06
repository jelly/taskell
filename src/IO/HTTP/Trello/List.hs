{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell #-}

module IO.HTTP.Trello.List
    ( List
    , cards
    , setCards
    , listToList
    ) where

import ClassyPrelude

import Control.Lens (makeLenses, (&), (.~), (^.))

import IO.HTTP.Aeson       (deriveFromJSON)
import IO.HTTP.Trello.Card (Card, cardToTask)

import qualified Data.Taskell.List as L (List, create)

data List = List
    { _name  :: Text
    , _cards :: [Card]
    } deriving (Eq, Show)

-- create Aeson code
$(deriveFromJSON ''List)

-- create lenses
$(makeLenses ''List)

-- operations
setCards :: List -> [Card] -> List
setCards list cs = list & cards .~ cs

listToList :: List -> L.List
listToList ls = L.create (ls ^. name) (fromList $ cardToTask <$> (ls ^. cards))
