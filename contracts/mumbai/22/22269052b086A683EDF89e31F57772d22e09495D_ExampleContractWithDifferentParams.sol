pragma solidity ^0.8.0;

contract ExampleContractWithDifferentParams {

    struct Foo {
        string id;
        string name;
    }

    struct Bar {
        uint id;
        Foo data;
        string name;
    }

    address payable public owner;
    uint public counter;

    event EventWithoutParams();
    event EventWithSimpleParams(address _address, string someString);
    event EventWithStructs(Bar _bar, string someString);
    event CounterUpdatedEvent(uint counter);

    constructor() {
        owner = payable(msg.sender);
    }

    function silentlyIncreaseCounter() public returns (uint) {
        counter += 1;
        return counter;
    }

    function emitEventWithoutParams() public returns (uint) {
        counter += 1;
        emit EventWithoutParams();
        emit CounterUpdatedEvent(counter);
        return counter;
    }

    function emitEventWithSimpleParams(address _address, string memory someString) public returns (uint) {
        counter += 1;
        emit EventWithSimpleParams(_address, someString);
        emit CounterUpdatedEvent(counter);
        return counter;
    }

    function emitEventWithStructs(Foo memory _foo, Bar calldata _bar, string calldata someString) public returns (uint) {
        counter += 1;
        emit EventWithStructs(_bar, someString);
        emit CounterUpdatedEvent(counter);
        return counter;
    }
}