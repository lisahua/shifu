/**
 * Copyright [2012-2014] eBay Software Foundation
 *  
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *  
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
REGISTER '$path_jar'

SET default_parallel $num_parallel
SET mapred.job.queue.name $queue_name;
SET job.name 'shifu post train'


DEFINE SimpleScore 		ml.shifu.shifu.udf.SimpleScoreUDF('$source_type', '$path_model_config', '$path_column_config', '$pathHeader', '$pathDelimiter');
DEFINE FullScore 		ml.shifu.shifu.udf.FullScoreUDF('$source_type', '$path_model_config', '$path_column_config', '$pathHeader', '$pathDelimiter');
DEFINE Scatter      	ml.shifu.shifu.udf.ScatterUDF('$source_type', '$path_column_config');
DEFINE CalculateBinAvgScore 	ml.shifu.shifu.udf.CalculateBinAvgScoreUDF('$source_type', '$path_column_config');


raw = LOAD '$pathSelectedRawData' USING PigStorage('$delimiter');

fullScore = FOREACH raw GENERATE FLATTEN(FullScore(*));

raw_scored = FOREACH raw GENERATE *, SimpleScore(*);

scattered = FOREACH raw_scored GENERATE FLATTEN(Scatter(*));

grouped = GROUP scattered BY $0;
binAvgScore = FOREACH grouped GENERATE FLATTEN(CalculateBinAvgScore(*));

STORE fullScore INTO '$pathTrainScore' USING PigStorage('|', '-schema');
STORE binAvgScore INTO '$pathBinAvgScore' USING PigStorage('|', '-schema');