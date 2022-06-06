/**
 *Submitted for verification at polygonscan.com on 2022-06-06
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.0;

interface IXVMCgovernor {
    function acPool1() external returns (address);
    function acPool2() external returns (address);
    function acPool3() external returns (address);
    function acPool4() external returns (address);
    function acPool5() external returns (address);
    function acPool6() external returns (address);
}

interface IToken {
    function governor() external view returns (address);
}

interface IacPool {
    function voteForProposal(uint256 proposalID) external;
    function setDelegate(address _delegate) external;
}

contract XVMCvotingProxy {
    address public immutable xvmcToken;
    
    address public acPool1;
    address public acPool2;
    address public acPool3;
    address public acPool4;
    address public acPool5;
    address public acPool6;


    constructor(address _xvmc) {
        xvmcToken = _xvmc;
    }


    function updatePools() external {
        address governor = IToken(xvmcToken).governor();

        acPool1 = IXVMCgovernor(governor).acPool1();
        acPool2 = IXVMCgovernor(governor).acPool2();
        acPool3 = IXVMCgovernor(governor).acPool3();
        acPool4 = IXVMCgovernor(governor).acPool4();
        acPool5 = IXVMCgovernor(governor).acPool5();
        acPool6 = IXVMCgovernor(governor).acPool6();
    }

    function proxyVote(uint256 _forID) external {
        IacPool(acPool1).voteForProposal(_forID);
        IacPool(acPool2).voteForProposal(_forID);
        IacPool(acPool3).voteForProposal(_forID);
        IacPool(acPool4).voteForProposal(_forID);
        IacPool(acPool5).voteForProposal(_forID);
        IacPool(acPool6).voteForProposal(_forID);
    }

    function proxySetDelegate(address _forWallet) external {
        IacPool(acPool1).setDelegate(_forWallet);
        IacPool(acPool2).setDelegate(_forWallet);
        IacPool(acPool3).setDelegate(_forWallet);
        IacPool(acPool4).setDelegate(_forWallet);
        IacPool(acPool5).setDelegate(_forWallet);
        IacPool(acPool6).setDelegate(_forWallet);
    }
}