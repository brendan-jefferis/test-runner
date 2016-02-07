module Component.Counter (Model, init, Action, update, view, stringToAction) where

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)

----------------------------------------------------------------------------------------------------| MODEL |----------

type alias Model =
  { count : Int
  }

init : Model
init =
  { count = 0
  }



----------------------------------------------------------------------------------------------------| UPDATE |----------

type Action
  = NoOp
  | Reset
  | Increment
  | Decrement
  | Double
  | Invert

update : Action -> Model -> Model
update action model =
  case action of
    NoOp ->
      model

    Reset ->
      { model |
          count = 0
      }

    Increment ->
      { model |
          count = model.count + 1
      }

    Decrement ->
      { model |
          count = model.count - 1
      }

    Double ->
      { model |
          count = model.count * 2
      }

    Invert ->
      { model |
          count = negate model.count
      }


----------------------------------------------------------------------------------------------------| VIEW |----------

view : Signal.Address Action -> Model -> Html
view address model =
  div
    [ class "counter-app" ]
    [ h2
        [ ]
        [ text "Counter" ]
    , p
        [ ]
        [ text ("Count: " ++ (toString model.count)) ]
    , button
        [ onClick address Decrement ]
        [ text "-1" ]
    , button
        [ onClick address Increment ]
        [ text "+1" ]
    , button
        [ onClick address Double ]
        [ text "x2" ]
    , button
        [ onClick address Invert ]
        [ text "Invert" ]
    , button
        [ onClick address Reset ]
        [ text "Reset" ]
    ]



----------------------------------------------------------------------------------------------------| SIGNALS |----------

actions : Signal.Mailbox Action
actions =
  Signal.mailbox NoOp

model : Signal Model
model =
  Signal.foldp update init actions.signal



----------------------------------------------------------------------------------------------------| HELPERS |----------

stringToAction : String -> Action
stringToAction str =
  case str of
    "Increment" ->
      Increment

    "Decrement" ->
      Decrement

    "Double" ->
      Double

    "Reset" ->
      Reset

    "Invert" ->
      Invert

    _ ->
      NoOp
