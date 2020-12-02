#!/bin/bash
#set -x


FIRST_REALLOC=1379128
BLOCK_TIME=2.625
SUPER_BLOCK_CYCLE=16616
HALVING_INTERVAL=210240
FIRST_REWARD_BLOCK=1261441
HALVING_REDUCTION_AMOUNT="1/14"
STARTING_BLOCK_REWARD=1.44236248
REALLOC_AMOUNT=(513 526 533 540 546 552 557 562 567 572 577 582 585 588 591 594 597 599 600)

current_block=$(dash-cli getblockcount)

blocks_per_year=$(printf '%.0f' $(echo "60/$BLOCK_TIME*24*365.25"|bc))
last_block_of_the_year=$((current_block+blocks_per_year))

enabled_mns=$(dash-cli masternode count|jq -r .enabled)

# General idea compute the reward for every n blocks and accumulate it.
# where n is the number of enabled MNs.
reward=0
for((block=current_block; block<last_block_of_the_year; block+=enabled_mns));do

	# Find which halving period we are on
	blocks_since_halving=$((block-FIRST_REWARD_BLOCK))
	halving_period=$((blocks_since_halving/HALVING_INTERVAL))

	# Find which realloc period we are on.
	blocks_since_realloc=$((block-FIRST_REALLOC))
	# We start counting our periods from zero, each realloc period lasts for 3 super blocks.
	period=$((blocks_since_realloc/(SUPER_BLOCK_CYCLE*3)))
	if ((period>18));then
		period=18
	fi

	# Combined bc statement.
	reward=$(echo "scale=8;base_reward=$STARTING_BLOCK_REWARD * (1 - $HALVING_REDUCTION_AMOUNT)^$halving_period;new_reward=base_reward / 500 * ${REALLOC_AMOUNT[$period]};$reward+new_reward"|bc -l)
done

roi=$(echo "scale=6;$reward/10"|bc)
echo "ROI = ${roi}%"

