%{



Width Specification:
--------------------
- seconds (we'll do this for now)
- samples 

Slider movement:
----------------
1) - side buttons - should be easy to be precise
2) - dragging slider - may allow for larger changes

At what point do we need to optimize the plotting??????
-------------------------------------------------------
If we are looking at 1 seconds worth of data at 20 kHz, we really don't
need to optimize the plotting, we can just take everything

Big Issues
----------
1) We can't always load everything from disk ...

This is potentially a big problem but something we'll delay handling for
now.

Some numbers:
20000 Hz Sampling
3600 seconds per hour
10 hours
= 0.072 GB
or with a double
0.5760 GB for 10 hours of data

2) Delaying rendering. The current behavior is to delay rendering until
manipulations are done, but if we are panning, we want results as quickly
as possible

3) Min/max alignment to the scrollbar

If we can keep the scrollbar aligned to precomputed min/max values, then
we never need to recompute min/max. If however we things shift, then we
might need to recompute. It seems like we should be able to oversample by
some factor (maybe 2) and then just toggle between being aligned to evens
or odds ...

This seems relatively easy for one plot, but not for multiple plots that 
are not well aligned

%}