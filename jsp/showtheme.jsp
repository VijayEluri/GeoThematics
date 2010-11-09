<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="geotheme.bean.*" %>
<% themeBean tb = (themeBean)request.getAttribute("themeBean"); %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML>
<HEAD>
<META http-equiv="Content-Type" content="text/html; charset=UTF-8">
<TITLE>Geoserver Thematics</TITLE>
<LINK rel="stylesheet" type="text/css" href="/geothematics/resources/css/ext-all.css" />

<SCRIPT type="text/javascript" src="/geothematics/lib/OpenLayers.js"></SCRIPT>
<SCRIPT type="text/javascript" src="/geothematics/lib/ext-base.js"></SCRIPT>
<SCRIPT type="text/javascript" src="/geothematics/lib/ext-all.js"></SCRIPT>

<!-- Localhost key -->
<script
  src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=<%= tb.getGoogleKey() %>"
  type="text/javascript">
</script>
    
<SCRIPT type="text/javascript">

  var map;
  var wmsLayer;
  
  var wmsServer    = "<%= tb.getWmsUrl() %>";
  var sldServer    = "<%= tb.getGsldUrl()%>";  
  var mLayers      = "<%= tb.getLayerName() %>";
  var mLayerType   = "<%= tb.getLayerType() %>";
  var mFormat      = "image/png";
  var mSRS         = "EPSG:900913"; //"EPSG:4326";

  function showMessage() {
      Ext.MessageBox.show({
          msg: 'Creating Theme on '+Ext.get('criteriaId').dom.value,
          progressText: 'Creating...',
          width:300,
          wait:true,
          waitConfig: {interval:200},
        //icon:'ext-mb-download', //custom class in msg-box.html
          animEl: 'mb7'
      });
  }

  function hideMessage() {
          Ext.MessageBox.hide();
  }
  
  function setThematics() {

      wmsLayer.setVisibility( false );
      Ext.get('mapLegend').update('&nbsp;',true);
      
      var criteria =  Ext.get('criteria').dom.value;
      var ranges   =  Ext.get('ranges'  ).dom.value;
      var themetype=  Ext.get('types'   ).dom.value;
      var color    =  Ext.get('colors'  ).dom.value;
      
      var params = "?typename=" +mLayers    +
                   "&geotype="  +mLayerType +
                   "&propname=" +criteria   +
                   "&numrange=" +ranges     +
                   "&typerange="+themetype  +
                   "&labscale=<%= tb.getLabelScale() %>"+
                   "&color="    +color;

      var m_url = sldServer+params;                      

      Ext.Ajax.on('beforerequest'   , showMessage, this);
      Ext.Ajax.on('requestcomplete' , hideMessage, this);
      Ext.Ajax.on('requestexception', hideMessage, this);

      Ext.Ajax.request({
    	   url: m_url,
    	   type:'POST',
    	   success: function() {
               this.setLegend();
               wmsLayer.redraw( true );
               map.setCenter( map.getCenter(),
                              map.getZoom(), 
                              false, true );
               wmsLayer.setVisibility( true );
           }
      });
  }

  function setLegend() {

      var date     = new Date();
      var imgHtml  = 
      "<center>"+Ext.get('criteriaId').dom.value+"<br /><br />"+    
      "<img border=0 src="+wmsServer+
      "?REQUEST=GetLegendGraphic"+
      "&FORMAT="+mFormat+
      "&LAYER="+mLayers+
      "&TRANSPARENT=TRUE"+
      "&SRS="+mSRS+            
      "&BBOX="+map.getExtent().toBBOX()+
      "&DATE="+date.getTime()+" id=\"legend\" /></center>";

      Ext.get("mapLegend").update(imgHtml,true);

  }
  
  function setOpenLayers() {
      
      // pink tile avoidance
      OpenLayers.IMAGE_RELOAD_ATTEMPTS = 5;
      // make OL compute scale according to WMS spec
      OpenLayers.DOTS_PER_INCH = 25.4 / 0.28;
  
      var bounds = new OpenLayers.Bounds(
              15001225.42105, 4028842.88629, 15174890.34929, 4196698.60039);
              
      var boundsGeoserver = new OpenLayers.Bounds(
              <%= tb.getBounds() %>);
  
      var options = {
              projection: mSRS,
              units: 'm',
            //restrictedExtent: bounds,
              maxResolution: 156543.0339,
              maxExtent: new OpenLayers.Bounds(-20037508, -20037508,
                                               20037508, 20037508)           
       };
  
	  map = new OpenLayers.Map('mapPanel',options);

	  wmsLayer = new OpenLayers.Layer.WMS(
              "Geoserver Presentation", 
              wmsServer,        
              {
                  transparent: true,
                  layers     : mLayers,
                  format     : mFormat,
                  tiled      : "TRUE",
                  tilesorigin: [map.maxExtent.left,map.maxExtent.bottom]                        
              },
              { isBaseLayer: false,
              //singleTile: true,
                tileSize: new OpenLayers.Size(512,512), 
                buffer: 0,
                displayInLayerSwitcher: false } 
          );
      
      var googleLayer = new OpenLayers.Layer.Google( 'Google',
              { 'minZoomLevel'     : 1,
                'maxZoomLevel'     : 20,
                'sphericalMercator': true
              },{isBaseLayer: true});
      var googlePhys  = new OpenLayers.Layer.Google( 'Google Physical',
              { 'minZoomLevel'     : 1,
                'maxZoomLevel'     : 20,
                'type'             : G_PHYSICAL_MAP,
                'sphericalMercator': true
              },{isBaseLayer: true});
          
       var googleSat   = new OpenLayers.Layer.Google( 'Google Satellite',
              { 'minZoomLevel'     : 1,
                'maxZoomLevel'     : 20,
                'type'             : G_SATELLITE_MAP,
                'sphericalMercator': true
              },{isBaseLayer: true});
       
      map.addLayers([googleLayer,googlePhys,googleSat,wmsLayer]);

      var geographic = new OpenLayers.Projection("<%= tb.getSrs() %>");
      var mercator   = new OpenLayers.Projection(mSRS);
        
      map.zoomToExtent( boundsGeoserver.transform(geographic, mercator));
      map.addControl(new OpenLayers.Control.LayerSwitcher());

      wmsLayer.setVisibility( false );
  }
  
  Ext.onReady(function() {

        //Ext.util.CSS.swapStyleSheet("theme","resources/css/xtheme-gray.css");

	    Ext.BLANK_IMAGE_URL = 'resources/images/default/s.gif';

	    var themeCriteria = new Ext.data.SimpleStore({
		    fields: ['idc','criteria'],
		    data  : [<%= tb.getPropList() %>] });
        
	    var themeRange = new Ext.data.SimpleStore({
		    fields: ['id','range'],
		    data  : [<%= tb.getThemeRanges() %>] });
	    
	    var themeType = new Ext.data.SimpleStore({
            fields: ['id','type'],
            data: [['EQRange','Equal Range'],
                   ['EQCount','Equal Count'],
                   ['Natural','Natural Breaks'],
                   ['Standard','Standard Deviation']]});

        var themeColor = new Ext.data.SimpleStore({
            fields: ['id','color'],
            data: [<%= tb.getColorNames() %>]});
        
	    var viewport = new Ext.Viewport({
	        layout: 'border',
	        id: 'mainpanel',
	        renderTo: Ext.get('tabs1'),
	        items: [	    	    
	            {region: 'east',xtype: 'panel',id: 'east',
		                        split: true, width:250,minSize:250,
		                        maxSize:250,collapsible: true,
		                        collapseMode: 'mini',title: 'Data Thematics',
		                        layout: 'border',		             		                                 
		                        items: [
		                             {region:'north',xtype:'form',	
		                              labelWidth: 40,
                                      bodyStyle: 'padding:15px 15px',   
			                          title: 'Parameters', height:220,
			                          items: [
                                        { xtype: 'combo',    
                                            fieldLabel: 'Criteria',                                           
                                            name: 'criteria',
                                            id: 'criteriaId',
                                            hiddenName: 'criteria',
                                            mode: 'local',
                                            store: themeCriteria,
                                            valueField: 'idc',
                                            displayField: 'criteria',
                                            forceSelection:true,
                                            allowBlank: false,
                                            editable: false,
                                            triggerAction: 'all',
                                            value: '<%= tb.getFirstProp() %>',
                                            width: 155
                                          },
			                              { xtype: 'combo',    
	                                        fieldLabel: 'Ranges',	                                        
	                                        name: 'ranges',
	                                        hiddenName: 'ranges',
	                                        mode: 'local',
	                                        store: themeRange,
	                                        valueField: 'id',
	                                        displayField: 'range',
	                                        forceSelection:true,
	                                        allowBlank: false,
	                                        editable: false,
	                                        triggerAction: 'all',
	                                        value: <%= tb.getFirstRange() %>,
	                                        width: 70
	                                      },
	                                      { xtype: 'combo',
	                                        fieldLabel: 'Type',
	                                        name: 'types',
	                                        hiddenName: 'types',
	                                        mode: 'local',
	                                        store: themeType,
	                                        valueField: 'id',
	                                        displayField: 'type',
	                                        forceSelection:true,
	                                        allowBlank: false,	  
	                                        editable: false,     
	                                        triggerAction: 'all',    
	                                        value: 'EQRange',                                 
	                                        width: 110
	                                      },
	                                      { xtype: 'combo',
                                            fieldLabel: 'Color',
                                            name: 'colors',
                                            hiddenName: 'colors',
                                            mode: 'local',
                                            store: themeColor,
                                            valueField: 'id',
                                            displayField: 'color',
                                            forceSelection:true,
                                            allowBlank: false,    
                                            editable: false,     
                                            triggerAction: 'all',    
                                            value: '<%= tb.getFirstColor() %>',                                 
                                            width: 110
	                                          }],
	                                      buttons: [{text:'Submit',id:'mapSub'},
	      	                                        {text: 'Reset',id:'mapRes'}] 
	      	                              },
	      	                            	                             	      		      	                             
	      	                              {region:'center',xtype:'panel',
	      	                               bodyStyle: 'padding:15px 15px',        
	      		      	                   title:'Legend', autoScroll: true,
	      		      	                   html:'<div id=\'mapLegend\'></div>'}
	      		      	               ]},

		        {region: 'center',xtype: 'panel', title:'Map',html: 
			       '<div id="mapPanel" style="width:100%;height:100%"></div>'}
			     
			]
	    })

        Ext.get('mapSub').on('click', function(){
            setThematics();
        });

        Ext.get('mapRes').on('click', function() {
            wmsLayer.setVisibility( false );
            Ext.get('mapLegend').update('&nbsp;',true);
        });
        this.setOpenLayers();        
  })
</SCRIPT>
</HEAD>
<BODY>

<div id="tabs1"></div>

</BODY>
</HTML>