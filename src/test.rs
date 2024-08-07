// use iced::{
//     core::{Element, Layout, Length, Point, Size, Widget},
//     widget::tree::{self, Tree},
//     Rectangle,
// };
use iced::executor;
use iced::mouse;
use iced::widget::canvas::{Cache, Geometry, Path};
use iced::widget::{canvas, container};
use iced::{
    Application, Color, Command, Element, Length, Point, Rectangle, Renderer, Settings, Size, Theme,
};

pub struct PositionAware;

impl<'a, Message> Widget<Message, iced::Renderer> for PositionAware {
    fn width(&self) -> Length {
        Length::Fill
    }

    fn height(&self) -> Length {
        Length::Fill
    }

    fn layout(
        &self,
        renderer: &iced::Renderer,
        limits: &iced::core::layout::Limits,
    ) -> iced::core::layout::Node {
        let size = limits.max();
        let bounds = Rectangle::new(Point::ORIGIN, size);
        iced::core::layout::Node::new(size)
    }

    fn draw(
        &self,
        tree: &Tree,
        renderer: &mut Renderer,
        theme: &iced::Renderer,
        style: &renderer::Style,
        layout: Layout<'_>,
        cursor: mouse::Cursor,
        viewport: &Rectangle,
    ) {
        let bounds = layout.bounds();
        println!("Widget position: {:?}", bounds);

        // Here you would normally draw your widget
    }
}

impl<'a, Message> From<PositionAware> for Element<'a, Message> {
    fn from(position_aware: PositionAware) -> Self {
        Self::new(position_aware)
    }
}
