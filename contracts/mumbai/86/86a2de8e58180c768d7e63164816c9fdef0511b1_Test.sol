/**
 *Submitted for verification at polygonscan.com on 2022-07-28
*/

contract Test {
          address _singleton;
          address public creator;
          bool public isInitialized;
          constructor() payable {
              creator = msg.sender;
          }
          function init() public {
              require(!isInitialized, "Is initialized");
              creator = msg.sender;
              isInitialized = true;
          }
          function masterCopy() public pure returns (address) {
              return address(0);
          }
          function forward(address to, bytes memory data) public returns (bytes memory result) {
              (,result) = to.call(data);
          }
      }