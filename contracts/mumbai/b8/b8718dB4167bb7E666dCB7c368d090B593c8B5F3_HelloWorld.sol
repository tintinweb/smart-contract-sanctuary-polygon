/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

pragma solidity ^0.8.6;


interface IHelloWorld {
    function sayHello(string memory data) external view returns(string memory);
}

contract HelloWorld is IHelloWorld {

    function sayHello(string memory data) external view override returns(string memory) {

        return(data);
        

    }

    

}