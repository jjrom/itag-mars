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
     * Data references
     */
    public $references = array(
        array(
            'dataset' => 'Mars 15M Geologic Map GIS Renovation',
            'publisher' => 'USGS Astrogeology Science Center',
            'author' => 'James A. Skinner, Jr.',
            'originator' => 'Trent Hare, Ken Tanaka',
            'description' => 'A digital adaptation of the hard-copy Viking Orbiter-based geologic maps of Mars. The western equatorial region was originally mapped by David H. Scott and K. L. Tanaka (USGS I-1802-A, 1986, 1:15M scale). The eastern equatorial region was originally mapped by Ronald Greeley and J. E. Guest (USGS I-1802-B, 1987, 1:15M scale). The north and south polar regions were originally mapped by K. L. Tanaka and D. H. Scott (USGS I-1802-C, 1987, 1:15M scale). A conference abstract submitted to the 37th Lunar and Planetary Science Conference outlines and discusses the rationale and methodology for the digitized version presented herein. The abstract reference is: Skinner, J. A., Jr, T. M. Hare, and K. L. Tanaka 2006, LPSC XXXVII, abstract #2331.',
            'modified' => '3 June 2019',
            'license' => 'Free of charge',
            'url' => 'https://astrogeology.usgs.gov/search/map/Mars/Geology/Mars15MGeologicGISRenovation'
        )
    );
    
    /*
     * Columns mapping per table
     */
    protected $columnsMapping = array(
        'geologic_unit' => array(
            'name' => 'unitname',
            'symbol' => 'unitsymbol'
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
        return $this->getGeology($rawResults);
    }

    /**
     * Return a clean geology tagging
     * 
     * @param array $rawResults
     */
    private function getGeology($rawResults)
    {

        $geology = array();

        if ( isset($rawResults['geologic_unit']) )
        {

            for ($i = 0, $ii = count($rawResults['geologic_unit']); $i < $ii; $i++) {
                if ( !isset($geology[$rawResults['geologic_unit'][$i]['symbol']]) ) {
                    $geology[$rawResults['geologic_unit'][$i]['symbol']] = array(
                        'id' => 'geologicunit'. iTag::TAG_SEPARATOR . strtolower($rawResults['geologic_unit'][$i]['symbol']),
                        'name' => ucfirst($rawResults['geologic_unit'][$i]['name']),
                        'pcover' => $rawResults['geologic_unit'][$i]['pcover']
                    );
                }
                else {
                    $geology[$rawResults['geologic_unit'][$i]['symbol']]['pcover'] += $rawResults['geologic_unit'][$i]['pcover'];
                }
            }    

        }

        return array(
            'geologic_units' => array_values($geology)
        );
    }

}
