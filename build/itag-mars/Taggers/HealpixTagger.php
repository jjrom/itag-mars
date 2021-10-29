<?php
/*
 * Copyright 2021 Jérôme Gasperi
 *
 * Licensed under the Apache License, version 2.0 (the "License");
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 */

class MarsGeologyTagger extends GenericTagger
{

    /*
     * This Tagger is specific to Mars
     */
    public $planet = 'mars';
    
    /*
     * Columns mapping per table
     */
    protected $columnsMapping = array(
        'healpix' => array(
            'level' => 'level',
            'pix' => 'pix'
        )
    );
    
    /**
     * Constructor
     *
     * @param DatabaseHandler $dbh
     * @param array $config
     */
    public function __construct($dbh, $config)
    {
        parent::__construct($dbh, $config);
    }
    
    /**
     * Tag metadata
     *
     * @param array $metadata
     * @param array $options
     * @return array
     * @throws Exception
     */
    public function tag($metadata, $options = array())
    {
        $rawResults = parent::tag($metadata, array_merge($options, array(
            'schema' => 'mars',
            'computeArea' => true)
        ));
        
        // Now sum up the same classes
        return $this->getHealpix($rawResults);
    }

    /**
     * Return a clean healpix tagging
     * 
     * @param array $rawResults
     */
    private function getHealpix($rawResults)
    {

        $healpix = array();

        if ( isset($rawResults['healpix']) )
        {

            for ($i = 0, $ii = count($rawResults['healpix']); $i < $ii; $i++) {
                $healpix[] = array(
                    'id' => 'healpix'. iTag::TAG_SEPARATOR . '00' . $rawResults['healpix'][$i]['level'] . $rawResults['healpix'][$i]['pix'],
                    'name' => 'Healpix order ' . $rawResults['healpix'][$i]['level'] . ', pixel ' . $rawResults['healpix'][$i]['pix'],
                    'pcover' => $rawResults['healpix'][$i]['pcover']
                );
            }    

        }

        return array(
            'healpix' => $healpix
        );
    }

}
