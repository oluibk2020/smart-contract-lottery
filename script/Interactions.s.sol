//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinatorNew = helperConfig.getConfig().vrfCoordinator;
        (uint64 subscriptionId,address vrfCoordinator) = createSubscription(vrfCoordinatorNew);
        return (subscriptionId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint64, address) {
        console.log("Creating subscription on chain id: ", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(uint96(0), uint96(0));
        
        uint64 subscriptionId = vrfCoordinatorMock.createSubscription();
        vm.stopBroadcast();
        console.log("Created subscription with id: ", subscriptionId);
        console.log("please update the subscription id in the HelperConfig.s.sol file");
        return (subscriptionId, vrfCoordinator);
    }

    //openchain.xyz - helps converts hash to name
    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subId, address account) public {
        console.log("Adding consumer contract: ", contractToAddToVrf);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinatorV2_5 = helperConfig.getConfig().vrfCoordinatorV2_5;
        address account = helperConfig.getConfig().account;

        addConsumer(mostRecentlyDeployed, vrfCoordinatorV2_5, subId, account);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}


contract FundSubscription is Script, CodeConstants {

   uint96 public constant FUND_AMOUNT = 3 ether; //3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        address link = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;

        if(subscriptionId == 0) {
             CreateSubscription createSub = new CreateSubscription();
            (uint256 updatedSubId, address updatedVRFv2) = createSub.run();
            subId = updatedSubId;
            vrfCoordinatorV2_5 = updatedVRFv2;
            console.log("New SubId Created! ", subId, "VRF Address: ", vrfCoordinatorV2_5);
        }
        fundSubscription(vrfCoordinatorV2_5, subId, link, account);
    }



    function fundSubscription(address vrfCoordinatorV2_5, uint256 subscriptionId, address link, address account) public {
        console.log("Funding subscription: ", subscriptionId);
        console.log("using vrfCoordinator: ", vrfCoordinatorV2_5);
        console.log("on chain id", block.chainid);

    if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fundSubscription(subscriptionId, FUND_AMOUNT * 100) ;
            vm.stopBroadcast();
        } else {
            console.log(LinkToken(link).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkToken(link).balanceOf(address(this)));
            console.log(address(this));
            vm.startBroadcast(account);
            LinkToken(link).transferAndCall(vrfCoordinatorV2_5, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();

            // vm.startBroadcast();
            // LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            // vm.stopBroadcast();
        }
        
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}