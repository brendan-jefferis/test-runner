# elm-test-runner

This prototype is a simple proof on concept for a new way of recording and running automated UI tests for Elm code. It is designed to be used by testers, with no programming knowledge required.

The purpose of this project was to offer an alternative to current UI automation methods (e.g., Selenium, Protractor etc) that rely on attaching event listeners to DOM elements - a technique that tends to be brittle and labour-intensive but is seen as the only way to achieve that goal. Thankfully, Elm provides opportunities for real improvement here.

#### HOW IT WORKS

The concept here is actually extremely straight-forward, thanks to Elm's design. In a regular Elm application (using the canonical Elm Architecture), all user events are stored in a `Signal` of `Action`. In our Counter example, those Actions are `Increment`, `Decrement`, `Invert`, etc.

Using `Signal.foldp`, we reduce those `Actions`, using our `update` function as the accumulator, giving us our current state.

When a test is being recorded, in addition to storing the `Action` in a `Signal` (so the Counter can function as normal) we push each action to a standard list, e.g., `[Increment, Increment, Decrement]`. Additionally, each test suite is saved with the starting state, the resulting state, and the name of the test case.

To run the tests - and obtain the result (i.e., the state that is arrived at after running your update function over the recorded actions) - we just use `List.foldl` on the list of actions, instead of `Signal.foldp` over the Signal of Actions; then compare the result of that operation to the resulting state that was recorded with the test suite.

#### BENEFITS

Since this completely bypasses the view there is no DOM targeting required, which has two key benefits:

1. These tests won't falsely break when the developer changes the view

2. The tests are executed in one line of code without the need for a browser or virtual DOM so the results are immediate

You could argue that the fact that the view is bypassed is a bad thing, but my argument is that end-to-end UI testing should be testing the application's logic, i.e., given x operations, will the application be in the expected state - which has nothing to do with presentation.

#### CURRRENT LIMITATIONS
1. I've quickly put this together as a proof of the core concept, but the component being tested is trivially simple. The tests here are actually more like unit tests. I believe this concept will work equally well with multiple components but it would require a slightly more sophisticated implementation. Probably along the lines of pushing the component name with the action in a tuple, e.g., `[(Counter, Increment), (OtherComponent, Foo)]` etc.

2. The testing suite (which lives in Main.elm) is too tightly coupled with Counter.elm. Ideally, this testing component would be able to be placed on top of any project with minimal wiring.

3. I had difficulty converting my list of Action names (strings) which I'd stored in localStorage back to a list of Elm Actions. I settled on a switch block in Counter.elm which is not sustainable. I'm still fairly new to Elm, I'm sure someone out there could solve this in a much better way.



#### INSTALLATION
1. Download or clone project
2. Start local web server (either by running `elm reactor` and navigating to localhost:8000/index.html; or by running `browser-sync start --server` from the project root
 

#### RECORDING TESTS
1. Click show tools to display the testing tools
2. Enter the name of a test (e.g., "As a user I want to <blah>" or whatever test conventions you're used to)
3. Click record
4. Interact with the counter UI
5. When finished, click "Save test"
6. Repeat for each test case

#### RUNNING TESTS
1. Click show tools to display the testing tools
2. Click "Run tests"
3. Try messing up your application logic (i.e., the update function in Counter.elm) and running the tests again - if you break the counter code, the tests should fail
