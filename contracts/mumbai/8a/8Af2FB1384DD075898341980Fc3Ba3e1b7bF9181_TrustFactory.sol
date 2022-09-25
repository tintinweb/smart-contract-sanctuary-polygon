//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Trust.sol";

contract TrustFactory {
    // factory contract onwer
    address private immutable trustFactoryOwner;

    // struct to store all the data of trust and trust factory contract
    struct trustFactoryStruct {
        uint256 trustIndex;
        uint256 percentage;
        uint256 gigCount;
        address trustContractAddress;
        address owner;
        address platformAddress;
    }

    // searching the struct data of trust and trust factory using owner/junior address
    mapping(address => trustFactoryStruct) public allTrustContracts;

    // owner address, onwer address will be used to search the user profile.
    mapping(address => address) public searchByAddress;

    // number of TrustContracts created
    uint256 public numOfTrustContracts;

    constructor(address _trustFactoryOwner) {
        trustFactoryOwner = _trustFactoryOwner;
    }

    function createTrustContract(uint256 _percentage, uint256 _gigCount)
        public
    {
        // Create a new trust contract
        Trust trust = new Trust(
            _percentage,
            msg.sender,
            _gigCount,
            address(this)
        );

        // Increment the number of Trust contracts
        numOfTrustContracts++;

        // Add the new trust contract to the mapping
        allTrustContracts[msg.sender] = (
            trustFactoryStruct(
                numOfTrustContracts,
                _percentage,
                _gigCount,
                address(trust),
                msg.sender,
                address(this)
            )
        );

        // search the profile by using owner address
        searchByAddress[msg.sender] = address(trust);
    }

    // get the balance of the contract
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // get the address of the contract
    function getAddressOfContract() public view returns (address) {
        return address(this);
    }

    // get the address of trustFactory contract owner
    function getAddressOfTrustFactoryOnwer() public view returns (address) {
        return trustFactoryOwner;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    // function to withdraw the fund from contract factory
    function withdraw(uint256 amount) external payable {
        if (msg.sender != trustFactoryOwner) {
            revert ONLY_ONWER_CAN_CALL_FUNCTION();
        }
        // sending money to contract owner
        (bool success, ) = trustFactoryOwner.call{value: amount}("");
        if (!success) {
            revert TRANSFER_FAILED();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

error SEND_MORE_FUNDS();
error TRANSFER_FAILED();
error ONLY_ONWER_CAN_CALL_FUNCTION();
error JOB_NOT_DONE();
error JOB_DONE();
error STILL_HAVE_TIME();

contract Trust {
    // address of owner
    address public immutable owner;

    // percentage of profit he/she is willing to give
    uint256 public immutable percentage;

    // number of gigs owner will give commionsion/cut to bielevers
    uint256 public immutable gigCount;

    // Arrays of supporters/Believers
    address[] public believers;

    // count of projects done
    uint256 public projectCount;

    // address of the trustFactory contract
    address payable public platformAddress;

    // contract creation time
    uint256 public contractCreationTime;

    constructor(
        uint256 _percentage,
        address _owner,
        uint256 _gigCount,
        address _platformAddress
    ) {
        // Store the address of the deployer as a payable address.
        // When we withdraw funds, we'll withdraw here.
        owner = payable(_owner);
        percentage = _percentage;
        gigCount = _gigCount;
        platformAddress = payable(_platformAddress);

        contractCreationTime = block.timestamp;
    }

    // adding senior / Believer to the believers array
    function AddBeliever() public payable {
        if (msg.value < 1e17) {
            // 1,00,000,000,000,000,000 = 1e17 = 1 * 10 * 17 = 0.1 Eth
            revert SEND_MORE_FUNDS();
        }
        believers.push(msg.sender);
    }

    // give money to believers and owner
    function gettingPaid(uint256 _amount) public payable {
        if (_amount < 1e14 || msg.value < _amount) {
            // 1,00,000,000,000,000 = 1e14 = 1 * 10 ** 14 =  0.0001 ETH
            revert SEND_MORE_FUNDS();
        }
        projectCount++;
        // sending money to believers
        uint256 believersAmount = (msg.value * percentage) / 100;
        if (believers.length >= 1) {
            for (uint256 i = 0; i < believers.length; i++) {
                (bool success, ) = believers[i].call{
                    value: believersAmount / believers.length
                }("");
                // require(success, "Transfer failed");
                if (!success) {
                    revert TRANSFER_FAILED();
                }
            }
        }
        // sending money to contract owner
        (bool success1, ) = owner.call{value: msg.value - believersAmount}("");
        if (!success1) {
            revert TRANSFER_FAILED();
        }
    }

    // function to free owner from paying cut to bieleivers
    function freeOwner() public {
        if (msg.sender != owner) {
            revert ONLY_ONWER_CAN_CALL_FUNCTION();
        }
        if (projectCount < gigCount) {
            revert JOB_NOT_DONE();
        }

        // send stake money back to believers
        if (believers.length >= 1) {
            for (uint256 i = 0; i < believers.length; i++) {
                (bool success, ) = believers[i].call{
                    value: 1e17 / believers.length
                }(""); // 0.1 Ether
                if (!success) {
                    revert TRANSFER_FAILED();
                }
            }
        }

        // empty the array
        delete believers;
    }

    // function to get money to platform if the owner cannot able to perform and get gis and complete them
    function platformGettingPaid() public {
        if (projectCount > gigCount) {
            revert JOB_DONE();
        }
        // testing
        if (block.timestamp < contractCreationTime + 10 minutes) {
            revert STILL_HAVE_TIME();
        }
        // production
        // if(block.timestamp < contractCreationTime + 12 weeks){
        //     revert STILL_HAVE_TIME();
        // }
        (bool success1, ) = platformAddress.call{value: address(this).balance}(
            ""
        );
        if (!success1) {
            revert TRANSFER_FAILED();
        }
    }

    // get the balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // get the length of array
    function noOfBelievers() public view returns (uint256) {
        return believers.length;
    }

    // get the balance of owner
    function getOwnerBalance() public view returns (uint256) {
        return owner.balance;
    }

    // get the balance of 1st beliver
    function getBeliverBalance() public view returns (uint256) {
        return believers[0].balance;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}