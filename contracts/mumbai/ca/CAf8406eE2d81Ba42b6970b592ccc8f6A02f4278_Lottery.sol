/**
 *Submitted for verification at Etherscan.io on 2020-08-25
*/

pragma solidity 0.5.12;

import './AddrArrayLib.sol';

contract Lottery {
    using AddrArrayLib for AddrArrayLib.Addresses;
    AddrArrayLib.Addresses managers;
    address public creator;
    address payable[] public players;

    event PlayerEntered(address indexed player, uint256 value);
    event WinnerPicked(address indexed winner);

    constructor() public {
        managers.pushAddress(msg.sender);
        creator = msg.sender;
    }

    modifier restricted() {
        //require(msg.sender == manager, "only contract creator allowed");
        require(managers.exists(msg.sender), "only managers allowed");
        _;
    }

    function () external payable {
        require(msg.value > .0000001 ether, "must pay the minimum amount");
        require(players.length < 50, "maximally 50 players");
        emit PlayerEntered(msg.sender, msg.value);
        players.push(msg.sender);
    }

    // This RNG is not secure, for demonstration purposes only
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public restricted  returns (address) {
        uint index = random() % players.length;
        address payable winner = players[index];
        players = new address payable[](0);
        emit WinnerPicked(winner);
        winner.transfer(address(this).balance);
        return winner;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function addManager(address newManager) public restricted {
        managers.pushAddress(newManager);
    }
    function removeManager(address manager) public restricted {
        require(manager != creator, "creatpor cannot be removed.");
        managers.removeAddress(manager);
    }

       function getManagers() public view returns (address[] memory) {
        return managers.getAllAddresses();
    }

}

/*
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity >=0.4.25 <0.6.0;

library AddrArrayLib {
    using AddrArrayLib for Addresses;

    struct Addresses {
      address[]  _items;
    }

    /**
     * @notice push an address to the array
     * @dev if the address already exists, it will not be added again
     * @param self Storage array containing address type variables
     * @param element the element to add in the array
     */
    function pushAddress(Addresses storage self, address element) internal {
      if (!exists(self, element)) {
        self._items.push(element);
      }
    }

    /**
     * @notice remove an address from the array
     * @dev finds the element, swaps it with the last element, and then deletes it;
     *      returns a boolean whether the element was found and deleted
     * @param self Storage array containing address type variables
     * @param element the element to remove from the array
     */
    function removeAddress(Addresses storage self, address element) internal returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                self._items[i] = self._items[self.size() - 1];
                self._items.pop();
                return true;
            }
        }
        return false;
    }

    /**
     * @notice get the address at a specific index from array
     * @dev revert if the index is out of bounds
     * @param self Storage array containing address type variables
     * @param index the index in the array
     */
    function getAddressAtIndex(Addresses storage self, uint256 index) internal view returns (address) {
        require(index < size(self), "the index is out of bounds");
        return self._items[index];
    }

    /**
     * @notice get the size of the array
     * @param self Storage array containing address type variables
     */
    function size(Addresses storage self) internal view returns (uint256) {
      return self._items.length;
    }

    /**
     * @notice check if an element exist in the array
     * @param self Storage array containing address type variables
     * @param element the element to check if it exists in the array
     */
    function exists(Addresses storage self, address element) internal view returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice get the array
     * @param self Storage array containing address type variables
     */
    function getAllAddresses(Addresses storage self) internal view returns(address[] memory) {
        return self._items;
    }

}