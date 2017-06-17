--
-- Jan & Uwe R. Zimmer, Australia, July 2011
--

with Ada.Real_Time; use Ada.Real_Time;

package Graphics_FrameRates is

   Smoothing_Buffer_Size : constant Positive := 24;

   subtype Hz is Float range 0.0 .. Float'Last;

   function Measure_Interval return Time_Span;

   function Average_Framerate (Interval : Time_Span) return Hz;

   procedure Framerate_Limiter (Max_Framerate : Hz);

end Graphics_FrameRates;
