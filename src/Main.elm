import Component.Counter as Counter

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import String
import Regex



----------------------------------------------------------------------------------------------------| MODEL |----------

type alias Model =
  { counter : Counter.Model
  , actions : List Counter.Action
  , caseName : String
  , showTools : Bool
  , recording : Bool
  , running : Bool
  , initialState : Counter.Model
  , suite : List TestCase
  }

emptyModel : Model
emptyModel =
  { counter = Counter.init
  , actions = []
  , caseName = ""
  , showTools = False
  , recording = False
  , running = False
  , initialState = Counter.init
  , suite = []
  }

type alias TestCase =
  { name : String
  , initialState : Counter.Model
  , finalState : Counter.Model
  , actions : List Counter.Action
  , passed : Bool
  }

type alias JSTestCase =
  { name : String
  , initialState : Counter.Model
  , finalState : Counter.Model
  , actions : String
  , passed : Bool
  }


----------------------------------------------------------------------------------------------------| UPDATE |----------

type Action
  = NoOp
  | Counter Counter.Action
  | SetCaseName String
  | ToggleTestTools
  | Record
  | Save
  | Cancel
  | DeleteAll
  | Run

update : Action -> Model -> Model
update action model =
  case action of
    NoOp ->
      model

    Counter act ->
      let
        actions = if model.recording then model.actions ++ [act] else model.actions
      in
        { model |
            counter = Counter.update act model.counter
          , actions = actions
        }

    SetCaseName str ->
      { model |
          caseName = str
      }

    ToggleTestTools ->
      { model |
          showTools = not model.showTools
      }

    Record ->
      { model |
          recording = True
        , showTools = False
        , caseName = model.caseName
        , initialState = model.counter
      }

    Cancel ->
      { model |
          recording = False
        , caseName = ""
        , actions = []
        , initialState = model.counter
      }

    Save ->
      let
        suite = model.suite ++ [newTestCase model]
      in
        { model |
            recording = False
          , showTools = True
          , caseName = ""
          , actions = []
          , initialState = Counter.init
          , suite = suite
        }

    DeleteAll ->
      { model |
          suite = []
      }

    Run ->
      let
        suite = List.map runTest model.suite
      in
        { model |
            running = True
          , suite = suite
        }




----------------------------------------------------------------------------------------------------| VIEW |----------

view : Signal.Address Action -> Model -> Html
view address model =
  div
    [ ]
    [ div
        [ class "test-runner" ]
        [ testToolBarView address model
        , if model.showTools then testToolsView address model
          else div [] []
        ]
    , Counter.view (Signal.forwardTo address Counter) model.counter
    ]


testToolBarView : Signal.Address Action -> Model -> Html
testToolBarView address model =
  div
    [ class "tool-bar" ]
    [ div
        [ class ("icon-record" ++ (if model.recording then " recording" else "")) ]
        [ ]
    , span
        [ class "recording-status" ]
        [ text (if model.recording then "Recording..." else "Not recording")]
    , button
       [ onClick address ToggleTestTools
       , class "button-tiny show-tools"
       ]
       [ text (if model.showTools then "Hide tools" else "Show tools") ]
    , button
       [ onClick address Save
       , class "button-tiny"
       , hidden (not model.recording)
       ]
       [ text "Save test" ]
    , button
       [ onClick address Cancel
       , class "button-tiny"
       , hidden (not model.recording)
       ]
       [ text "Cancel" ]
    ]

testToolsView : Signal.Address Action -> Model -> Html
testToolsView address model =
  div
    [ class "test-tools" ]
    [ label
        [ ]
        [ text "Test name" ]
    , input
        [ onInput address SetCaseName
        , value model.caseName
        , type' "text"
        , class "case-name"
        , placeholder "e.g. When user clicks x result should be y"
        ]
        [ ]
    , button
        [ onClick address Record
        , disabled (model.caseName == "")
        ]
        [ text (if model.recording then "Save" else "Record") ]
    , button
        [ onClick address Run
        , disabled (List.length model.suite == 0)
        ]
        [ text "Run tests" ]
    , button
        [ onClick address DeleteAll
        , disabled (List.length model.suite == 0)
        ]
        [ text "Delete tests" ]
    , if List.isEmpty model.suite then
        div [] []
      else
        table
          [ ]
          [ thead
            [ ]
            [ th
                [ ]
                [ text "Name" ]
            , th
                [ ]
                [ text "Given"]
            , th
                [ ]
                [ text "When"]
            , th
                [ ]
                [ text "Then"]
            ]
          , tbody
              [ ]
              (List.map testCaseView model.suite)
          ]
    , if model.running && not (List.isEmpty model.suite) then
        table
          [ class "results" ]
          [ thead
              [ ]
              [ th
                  [ ]
                  [ text "Case name" ]
              , th
                 [ ]
                 [ text "Result" ]
              ]
          , tbody
              [ ]
              (List.map resultView model.suite)
          ]
      else
        div [] []
    ]

testCaseView : TestCase -> Html
testCaseView model =
  tr
    [ class "test-case" ]
    [ td
        [ class "name" ]
        [ text model.name ]
    , td
        [ class "init-state" ]
        [ text (toString model.initialState) ]
    , td
        [ class "actions" ]
        [ toString model.actions
            |> formatListString
            |> text
        ]
    , td
        [ class "final-state" ]
        [ text (toString model.finalState) ]
    ]


resultView : TestCase -> Html
resultView model =
  tr
    [ class (if model.passed then "test pass" else "test fail") ]
    [ td
        [ class "name"]
        [ text model.name ]
    , td
        [ class "result" ]
        [ text (if model.passed then "Passed" else "Fail") ]
    ]



----------------------------------------------------------------------------------------------------| START |----------

main : Signal Html
main =
  Signal.map (view actions.address) model



----------------------------------------------------------------------------------------------------| SIGNALS |----------

actions : Signal.Mailbox Action
actions =
  Signal.mailbox NoOp

model : Signal Model
model =
  Signal.foldp update initialModel actions.signal


initialModel : Model
initialModel =
  Maybe.withDefault emptyModel (Maybe.map elmTestSuite incomingTestSuite)



----------------------------------------------------------------------------------------------------| PORTS |----------

port incomingTestSuite : Maybe (List JSTestCase)

port outgoingTestSuite : Signal (List JSTestCase)
port outgoingTestSuite = Signal.map jsTestSuite model



----------------------------------------------------------------------------------------------------| HELPERS |----------

newTestCase : Model -> TestCase
newTestCase model =
  { name = model.caseName
  , initialState = model.initialState
  , finalState = model.counter
  , actions = model.actions
  , passed = False
  }

runTest : TestCase -> TestCase
runTest testCase =
  let
    result = List.foldl Counter.update testCase.initialState testCase.actions
  in
    { testCase |
        passed = testCase.finalState == result
    }

sanitizeActions : TestCase -> JSTestCase
sanitizeActions model =
  { model |
      name = model.name
    , initialState = model.initialState
    , finalState = model.finalState
    , actions = toString model.actions
  }

toElmTestCase : JSTestCase -> TestCase
toElmTestCase model =
  { model |
      name = model.name
    , initialState = { count = model.initialState.count } -- TODO figure out where _ = {} comes from
    , finalState = { count = model.finalState.count } -- TODO figure out where _ = {} comes from
    , actions = toCounterActions model.actions
  }

jsTestSuite : Model -> List JSTestCase
jsTestSuite model =
  List.map sanitizeActions model.suite

elmTestSuite : List JSTestCase -> Model
elmTestSuite testCases =
    { counter = Counter.init
    , actions = []
    , caseName = ""
    , showTools = False
    , recording = False
    , running = False
    , initialState = Counter.init
    , suite = List.map toElmTestCase testCases
    }

toCounterActions : String -> List Counter.Action
toCounterActions actions =
  String.slice 1 (String.length actions - 1) actions
    |> String.split ","
    |> List.map Counter.stringToAction

onInput : Signal.Address a -> (String -> a) -> Attribute
onInput address contentToValue =
    on "input" targetValue (\str -> Signal.message address (contentToValue str))

formatListString : String -> String
formatListString str =
  String.slice 1 (String.length str - 1) str
    |> Regex.replace Regex.All (Regex.regex ",") (\_ -> ", ")