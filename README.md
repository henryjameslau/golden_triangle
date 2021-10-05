# Golden Triangle

The ['Golden Triangle'](https://www.wired.co.uk/article/warehouses-next-day-delivery) is an area in the East Midlands that has a high density of warehouses and distribution facilities because it provides access to over 90% of the UK population within a 4 hours drive. There is no definitive boundary but the 'Golden Triangle' seems to stretch between Nottingham, Kidderminster and Biggleswade.

![Golden Triangle](https://www.thenxgroup.com/wp-content/uploads/2016/04/The-Golden-Triangle-300x200.jpg)      
Image: [NX Group](https://www.thenxgroup.com/2017/08/02/golden-triangle-logistics)

1) Run an instance of the [Open Source Routing Machine (OSRM)](http://project-osrm.org) using [Docker](https://github.com/Project-OSRM/osrm-backend).
2) Create 4-hour drive time polygons from the centroids of a [1km by 1km 2011 Census population grid](https://catalogue.ceh.ac.uk/documents/0995e94d-6d42-40c1-8ed4-5090d82471e1) using the [osrm](https://cran.r-project.org/web/packages/osrm/index.html) package in R. 
