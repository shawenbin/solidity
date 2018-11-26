/*
https://github.com/shawenbin/Dapp1
uint of amount is Gwei
emit 一个 event 记录游戏过程 
*/
pragma solidity ^0.5.0;
contract Dapp1 {
    gameConfig public config;
    team[] public Teams;
    enum teamRule { dictatorship, democratic, originator }  // maximum amount, subtotal everyone, who creat team
    enum Country_Region { China, Japan, UN }
    mapping(address => uint56) public withdrawable; // Available eth can draw in Wei
    struct gameConfig {
        address developer;
        uint8 currertRound;     // max 256
        uint16 currertGame;     // max 16777216
        uint56[2] teamCharge;   // cost of building a team in Gwei, fibonacci number, [last, current]
        uint dateNode;          // defint endTime
    }
    struct team {
        address originator;
        string name;
        string introduce;
        Country_Region comeFrom;
        teamRule rule;
        uint8[2] lifeCycle; // [first, last] round
        uint8 attackIndex;  // team's index in arrary
        uint56 amount;      // max 72,057,594 eth
        uint56 totalInjury;
        member[] Members;
    }
    struct member {
        address addr;
        string message;
        uint8 attackIndex;  // max 256
        uint56 amount;
    }
    constructor() public {
        config = gameConfig({developer:msg.sender, currertGame:0, currertRound:0, teamCharge:[uint56(1),2], dateNode:now});
        newGame();
    }
    function newGame() private {
        config.teamCharge = [1,2];
        Teams.length = 1;
        (Teams[0].originator,                        Teams[0].name,   Teams[0].introduce, Teams[0].comeFrom)
        =(        msg.sender, "United Nations Peacekeeping Forces", "Welcome to Join us", Country_Region.UN);
        (       Teams[0].rule,                        Teams[0].lifeCycle, Teams[0].attackIndex)
        =(teamRule.democratic, [config.currertRound,config.currertRound],                    1);
    }
    function newTeam(Country_Region comeFrom, teamRule rule, string memory name, string memory introduce, uint8 attackIndex, string memory message) public payable {
        uint56 amount = uint56(msg.value / 1000000000 - config.teamCharge[1]);
        require(amount > 0, "The amount is not enough to build up a team.");
        require(attackIndex <= Teams.length, "The direction of attack is incorrect.");
        withdrawable[config.developer] += config.teamCharge[1]; // team building cost transfer to developer account       
        config.teamCharge = [config.teamCharge[1], config.teamCharge[0] + config.teamCharge[1]];    // calculate next fibonacci number
        Teams.length++;
        (Teams[Teams.length-1].originator, Teams[Teams.length-1].name, Teams[Teams.length-1].introduce, Teams[Teams.length-1].comeFrom)
        =(                     msg.sender,                       name,                       introduce,                       comeFrom);
        (Teams[Teams.length-1].rule,           Teams[Teams.length-1].lifeCycle, Teams[Teams.length-1].attackIndex, Teams[Teams.length-1].amount)
        =(                     rule, [config.currertRound,config.currertRound],                       attackIndex,                       amount);
        Teams[Teams.length-1].Members.push(member({addr:msg.sender, message:message, amount:amount, attackIndex:attackIndex}));
        if(attackIndex < Teams.length)
            Teams[attackIndex].totalInjury += amount;
        }
    function joinTeam(uint8 teamIndex, uint8 attackIndex, string memory message) public payable {
        uint56 amount = uint56(msg.value / 1000000000);
        require(amount > 0, "The amount must be greater than 1 Gwei.");
        require(attackIndex <= Teams.length, "The direction of attack is incorrect.");
        for(uint128 i = 0; i < Teams[teamIndex].Members.length; i++) {
            if(Teams[teamIndex].Members[i].addr == msg.sender) {    // has joined before
                amount += Teams[teamIndex].Members[i].amount;
                while (i++ < Teams[teamIndex].Members.length - 1)
                    Teams[teamIndex].Members[i-1] = Teams[teamIndex].Members[i];    // move this member to the end , in order to get last 3 messages
                Teams[teamIndex].Members[i-1] = member({addr:msg.sender, message:message, amount:amount, attackIndex:attackIndex});
                break;
            }
        }
        uint8 i = 0;
        if(i == Teams[teamIndex].Members.length)                    // first time to join
            Teams[teamIndex].Members.push(member({addr:msg.sender, message:message, amount:amount, attackIndex:attackIndex}));
        Teams[teamIndex].amount += amount;
        sumAttack(teamIndex);
    }
    function attackTeam(uint8 attackIndex) public payable {
        require(attackIndex <= Teams.length, "The direction of attack is incorrect.");
        // check every team
    }
    function sumAttack(uint8 index) public {
        uint56 maxAmount = 0;
        uint24 i;
        if(Teams[index].rule == teamRule.dictatorship) {    // maximum amount is leader
            for(i = 0; i < Teams[index].Members.length; i++) {
                if(Teams[index].Members[i].amount >= maxAmount)
                    (maxAmount, Teams[index].attackIndex) = (Teams[index].Members[i].amount, Teams[index].Members[i].attackIndex);
            }
        }
        else if(Teams[index].rule == teamRule.democratic) { // subtotal everyone
            uint56[] memory totalAttacks = new uint56[](Teams.length+1);
            for(i = 0; i < Teams[index].Members.length; i++) {
                totalAttacks[Teams[index].Members[i].attackIndex] += Teams[index].Members[i].amount;
                if(totalAttacks[Teams[index].Members[i].attackIndex] >= maxAmount)
                    (Teams[index].attackIndex, maxAmount) = (Teams[index].Members[i].attackIndex, totalAttacks[Teams[index].Members[i].attackIndex]);
            }
        }
    }
    function stateCheck() public {
        if(now >= config.dateNode + 1 days) {
            uint8 i;
            for(i = 0; i < Teams.length; i++) // clear totalInjury
                Teams[i].totalInjury = 0;
            uint8 eliminateIndex;   // eliminate Team's index number in teams arrary
            uint56 maxInjury;       // max injury
            uint56 denominator;     // total Gwei in this round
            for(i = 0; i < Teams.length; i++) {     // re count
                if(Teams[Teams[i].attackIndex].lifeCycle[1] == config.currertRound) {
                    Teams[Teams[i].attackIndex].totalInjury += Teams[i].amount;
                    denominator += Teams[i].amount;
                    if(Teams[Teams[i].attackIndex].totalInjury > maxInjury)
                        (eliminateIndex, Teams[Teams[i].attackIndex].totalInjury) = (Teams[i].attackIndex, maxInjury);
                }
            }
            denominator -= Teams[eliminateIndex].amount;
            uint56 numerator = Teams[eliminateIndex].amount * 19 / 20;  // 5 percents developer fee
            withdrawable[config.developer] += Teams[eliminateIndex].amount - numerator;
            for(i = 0; i < Teams.length; i++) {     // promote
                if(Teams[i].lifeCycle[1] == config.currertRound && i != eliminateIndex) {
                    Teams[i].lifeCycle[1]++;
                    for(uint24 j = 0; j < Teams[i].Members.length; j++)
                        withdrawable[Teams[i].Members[j].addr] += Teams[i].Members[j].amount * numerator / denominator;
                }
            }
            Teams[Teams[eliminateIndex].attackIndex].totalInjury -= Teams[eliminateIndex].amount;
            config.dateNode += 1 days;
        }
        if(Teams.length > 2)    // goto next round
            config.currertRound++;
        else {                  // goto next game

        }
    }
}
